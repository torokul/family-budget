import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart' as m;
import '../providers/budget_provider.dart';
import '../services/currency_service.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<m.Transaction> _txs = [];
  bool _loading = true;

  late DateTime _from;
  late DateTime _to;
  String? _typeFilter; // null = все, 'income', 'expense'

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to   = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    _loadTx();
  }

  Future<void> _loadTx() async {
    setState(() => _loading = true);
    final txs = await context.read<BudgetProvider>().fetchTransactions(
        from: _from, to: _to, type: _typeFilter);
    if (mounted) setState(() { _txs = txs; _loading = false; });
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF4A148C)),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _from = range.start;
        _to   = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      });
      _loadTx();
    }
  }

  void _setType(String? type) {
    setState(() => _typeFilter = (_typeFilter == type) ? null : type);
    _loadTx();
  }

  Future<void> _confirmDelete(m.Transaction tx) async {
    final provider = context.read<BudgetProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить операцию?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.deleteTransaction(tx.id!);
      if (mounted) _loadTx();
    }
  }

  void _showDetail(m.Transaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DetailSheet(tx: tx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd.MM.yy', 'ru_RU');

    return Scaffold(
      appBar: AppBar(title: const Text('История операций')),
      body: Column(children: [

        // ── Фильтр-бар ──────────────────────────────────────────
        Container(
          color: const Color(0xFFF5F5F5),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(children: [
            // Период
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(
                  '${dateFmt.format(_from)} — ${dateFmt.format(_to)}',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4A148C),
                  side: const BorderSide(color: Color(0xFF4A148C)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _TypeChip(
              label: 'Все',
              selected: _typeFilter == null,
              color: Colors.grey.shade600,
              onTap: () => _setType(null),
            ),
            const SizedBox(width: 4),
            _TypeChip(
              label: 'Доходы',
              selected: _typeFilter == 'income',
              color: const Color(0xFF2E7D32),
              onTap: () => _setType('income'),
            ),
            const SizedBox(width: 4),
            _TypeChip(
              label: 'Расходы',
              selected: _typeFilter == 'expense',
              color: const Color(0xFFC62828),
              onTap: () => _setType('expense'),
            ),
          ]),
        ),

        // ── Список ───────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _txs.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Нет операций за выбранный период',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _txs.length,
                      itemBuilder: (_, i) {
                        final tx = _txs[i];
                        return GestureDetector(
                          onDoubleTap: () => _showDetail(tx),
                          child: TransactionTile(
                            tx: tx,
                            onEdit: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(
                                    builder: (_) => AddTransactionScreen(existing: tx)));
                              _loadTx();
                            },
                            onDelete: () => _confirmDelete(tx),
                          ),
                        );
                      },
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_transactions',
        backgroundColor: const Color(0xFF4A148C),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
          _loadTx();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Чип типа операции ─────────────────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(25) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? color : Colors.black54,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Детали операции (нижний лист) ─────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final m.Transaction tx;
  const _DetailSheet({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == 'income';
    final amtColor = isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final catColor = tx.categoryColor != null ? Color(tx.categoryColor!) : Colors.grey;
    final icon = tx.categoryIcon != null
        // ignore: non_const_argument_for_const_parameter
        ? IconData(tx.categoryIcon!, fontFamily: 'MaterialIcons')
        : Icons.category;
    final fmt     = NumberFormat('#,##0.##', 'ru_RU');
    final dateFmt = DateFormat('dd MMMM yyyy, HH:mm', 'ru_RU');
    final provider = context.read<BudgetProvider>();
    final kgsAmount = provider.toKgs(tx.amount, tx.currency);
    final showKgs = tx.currency != 'KGS';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Заголовок
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: catColor.withAlpha(30),
              child: Icon(icon, color: catColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.categoryName ?? '—',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              Text(isIncome ? 'Доход' : 'Расход',
                  style: TextStyle(
                      fontSize: 12,
                      color: amtColor,
                      fontWeight: FontWeight.w500)),
            ])),
            Text(
              '${isIncome ? '+' : '−'}${fmt.format(tx.amount)}'
              ' ${CurrencyService.flags[tx.currency] ?? ''} ${tx.currency}',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: amtColor),
            ),
          ]),

          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 10),

          // Строки деталей
          _row(Icons.calendar_today_outlined, 'Дата и время',
              dateFmt.format(tx.date)),
          if (showKgs)
            _row(Icons.currency_exchange_outlined, 'Сумма в KGS',
                '≈ ${fmt.format(kgsAmount)} KGS'),
          if (tx.comment != null && tx.comment!.isNotEmpty)
            _row(Icons.comment_outlined, 'Примечание', tx.comment!),

          // Вложенный файл / чек
          if (tx.receiptBase64 != null) ...[
            const SizedBox(height: 14),
            Row(children: [
              Icon(Icons.attach_file, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text('Прикреплённый файл',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
            ]),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showFullImage(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(children: [
                  Image.memory(
                    base64Decode(tx.receiptBase64!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 8, bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min,
                          children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Увеличить',
                            style: TextStyle(
                                color: Colors.white, fontSize: 11)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 17, color: Colors.grey.shade400),
      const SizedBox(width: 10),
      Text(label,
          style: const TextStyle(fontSize: 13, color: Colors.black45)),
      const Spacer(),
      const SizedBox(width: 16),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.end,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    ]),
  );

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(base64Decode(tx.receiptBase64!)),
            ),
          ),
        ),
      ),
    );
  }
}
