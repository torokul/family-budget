import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../services/currency_service.dart';

class TransactionTile extends StatelessWidget {
  final Transaction tx;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == 'income';
    final color    = isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final catColor = tx.categoryColor != null ? Color(tx.categoryColor!) : Colors.grey;
    final icon = tx.categoryIcon != null
        // ignore: non_const_argument_for_const_parameter
        ? IconData(tx.categoryIcon!, fontFamily: 'MaterialIcons')
        : Icons.category;
    final fmt     = NumberFormat('#,##0.##', 'ru_RU');
    final dateFmt = DateFormat('dd MMM, HH:mm', 'ru_RU');
    final provider = context.watch<BudgetProvider>();
    final kgsAmount = provider.toKgs(tx.amount, tx.currency);
    final showKgs = tx.currency != 'KGS';

    // Проверка превышения плана (только для расходов)
    double? overAmount;
    if (!isIncome) {
      final plan = provider.planForCategory(tx.categoryId);
      if (plan > 0) {
        final spent = provider.spentForCategory(tx.categoryId);
        if (spent > plan) overAmount = spent - plan;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: catColor.withAlpha(30),
              child: Icon(icon, color: catColor, size: 20),
            ),
            title: Row(children: [
              Text(tx.categoryName ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (tx.receiptBase64 != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.receipt, size: 14, color: Colors.grey),
              ],
            ]),
            subtitle: Text(
              tx.comment != null && tx.comment!.isNotEmpty
                  ? '${dateFmt.format(tx.date)} · ${tx.comment}'
                  : dateFmt.format(tx.date),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    '${isIncome ? '+' : '-'}${fmt.format(tx.amount)} ${CurrencyService.flags[tx.currency] ?? ''} ${tx.currency}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (showKgs)
                    Text(
                      '≈ ${fmt.format(kgsAmount)} KGS',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ]),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (v) {
                    if (v == 'edit')    onEdit();
                    if (v == 'delete')  onDelete();
                    if (v == 'receipt' && tx.receiptBase64 != null) {
                      _showReceipt(context);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit',   child: Text('Изменить')),
                    if (tx.receiptBase64 != null)
                      const PopupMenuItem(value: 'receipt', child: Text('Посмотреть чек')),
                    const PopupMenuItem(value: 'delete', child: Text('Удалить')),
                  ],
                ),
              ],
            ),
          ),
          // Превью чека (маленькое)
          if (tx.receiptBase64 != null)
            GestureDetector(
              onTap: () => _showReceipt(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(tx.receiptBase64!),
                    height: 80,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // Плашка превышения лимита
          if (overAmount != null)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFB71C1C),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 6),
                const Text(
                  'План превышен на ',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '+${fmt.format(overAmount)} KGS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _showReceipt(BuildContext context) {
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
