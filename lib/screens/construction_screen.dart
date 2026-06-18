import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/construction_section.dart';
import '../models/construction_item.dart';
import '../providers/budget_provider.dart';

class ConstructionScreen extends StatelessWidget {
  const ConstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final fmt      = NumberFormat('#,##0', 'ru_RU');
    final sections = provider.cSections;
    final totals   = provider.cTotals;

    final totalPlan  = sections.fold(0.0, (s, sec) => s + sec.planAmount);
    final totalSpent = sections.fold(0.0, (s, sec) => s + (totals[sec.id] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Строительство дома'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadConstruction(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Summary
          Card(
            color: const Color(0xFF4A148C),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Row(children: [
                  Icon(Icons.home_work_outlined, color: Colors.white70, size: 20),
                  SizedBox(width: 8),
                  Text('Общий бюджет строительства',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _summaryCol('Бюджет', totalPlan, Colors.white70, fmt),
                  _summaryCol('Потрачено', totalSpent,
                      totalSpent > totalPlan ? const Color(0xFFEF9A9A) : const Color(0xFF81C784), fmt),
                  _summaryCol('Остаток', totalPlan - totalSpent,
                      (totalPlan - totalSpent) >= 0 ? const Color(0xFF81C784) : const Color(0xFFEF9A9A), fmt),
                ]),
                if (totalPlan > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (totalSpent / totalPlan).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        totalSpent > totalPlan ? const Color(0xFFEF9A9A) : const Color(0xFF81C784),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${(totalSpent / totalPlan * 100).toStringAsFixed(1)}% освоено',
                      style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),
          // Sections
          ...sections.map((sec) {
            final spent = totals[sec.id] ?? 0.0;
            return _SectionCard(section: sec, spent: spent, fmt: fmt);
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _summaryCol(String label, double val, Color color, NumberFormat fmt) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      const SizedBox(height: 4),
      Text(fmt.format(val),
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
    ]);
  }
}

// ── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatefulWidget {
  final ConstructionSection section;
  final double spent;
  final NumberFormat fmt;
  const _SectionCard({required this.section, required this.spent, required this.fmt});

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = false;
  List<ConstructionItem> _items = [];
  bool _loading = false;

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    _items = await context.read<BudgetProvider>().getConstructionItems(widget.section.id!);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final sec     = widget.section;
    final spent   = widget.spent;
    final plan    = sec.planAmount;
    final hasPlan = plan > 0;
    final over    = hasPlan && spent > plan;
    final pct     = hasPlan ? (spent / plan * 100).round() : null;
    final barColor = over ? const Color(0xFFD32F2F)
        : (pct != null && pct > 80) ? const Color(0xFFF57F17) : const Color(0xFF2E7D32);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // Header
        InkWell(
          onTap: () {
            setState(() => _expanded = !_expanded);
            if (_expanded) _loadItems();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: sec.color,
            child: Row(children: [
              Icon(sec.icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(sec.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Row(children: [
                    Text('${widget.fmt.format(spent)} KGS',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (hasPlan) ...[
                      const Text(' / ', style: TextStyle(color: Colors.white38)),
                      Text('${widget.fmt.format(plan)} KGS',
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ]),
                ]),
              ),
              if (pct != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$pct%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 4),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.white70, size: 18),
            ]),
          ),
        ),
        // Progress bar
        if (hasPlan)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (spent / plan).clamp(0.0, 1.0), minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
        // Items list
        if (_expanded) ...[
          const Divider(height: 1),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('Нет записей', style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          else
            ..._items.map((item) => ListTile(
              dense: true,
              title: Text(item.name, style: const TextStyle(fontSize: 13)),
              subtitle: item.date != null
                  ? Text(DateFormat('dd.MM.yyyy').format(item.date!),
                      style: const TextStyle(fontSize: 11))
                  : null,
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.fmt.format(item.amount),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (item.qty != 1 || item.price != 0)
                    Text('${item.qty} × ${widget.fmt.format(item.price)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            )),
          // Add item button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: OutlinedButton.icon(
              onPressed: () => _showAddItem(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить позицию', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: sec.color,
                side: BorderSide(color: sec.color),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  void _showAddItem(BuildContext context) {
    final nameCtrl   = TextEditingController();
    final amountCtrl = TextEditingController();
    final qtyCtrl    = TextEditingController(text: '1');
    final priceCtrl  = TextEditingController();
    final descCtrl   = TextEditingController();
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16, right: 16, top: 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Добавить позицию · ${widget.section.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Кол-во', border: OutlineInputBorder())),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(controller: priceCtrl, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Цена', border: OutlineInputBorder())),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Сумма (итого)', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Примечание', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setModal(() => selectedDate = d);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(selectedDate != null
                    ? DateFormat('dd.MM.yyyy').format(selectedDate!)
                    : 'Выбрать дату'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final qty    = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1;
                    final price  = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
                    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'))
                        ?? (qty * price);
                    if (amount <= 0) return;
                    await context.read<BudgetProvider>().addConstructionItem(ConstructionItem(
                      sectionId: widget.section.id!,
                      name: name,
                      qty: qty,
                      price: price,
                      amount: amount,
                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      date: selectedDate,
                    ));
                    await _loadItems();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Сохранить'),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }
}
