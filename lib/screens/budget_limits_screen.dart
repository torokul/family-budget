import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_limit.dart';
import '../providers/budget_provider.dart';

class BudgetLimitsScreen extends StatelessWidget {
  const BudgetLimitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final limits = provider.limits;
    final fmt = NumberFormat('#,##0', 'ru_RU');

    return Scaffold(
      appBar: AppBar(title: const Text('Лимиты бюджета')),
      body: Column(
        children: [
          Expanded(
            child: limits.isEmpty
                ? const Center(child: Text('Лимиты не заданы'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: limits.length,
                    itemBuilder: (_, i) {
                      final bl = limits[i];
                      final spent = provider.spentForCategory(bl.categoryId);
                      final pct = bl.limitAmount > 0 ? (spent / bl.limitAmount).clamp(0.0, 1.0) : 0.0;
                      final over = spent > bl.limitAmount;
                      final color = over
                          ? const Color(0xFFF44336)
                          : pct > 0.8
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF4CAF50);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              if (bl.categoryColor != null)
                                Container(
                                  width: 10, height: 10,
                                  decoration: BoxDecoration(color: Color(bl.categoryColor!), shape: BoxShape.circle),
                                ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(bl.categoryName ?? '—',
                                  style: const TextStyle(fontWeight: FontWeight.w600))),
                              if (over) const Icon(Icons.warning, color: Color(0xFFF44336), size: 18),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () => provider.deleteLimit(bl.id!),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('${fmt.format(spent)} / ${fmt.format(bl.limitAmount)}',
                                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                              Text('${(pct * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(fontSize: 12, color: color)),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLimit(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLimit(BuildContext context, BudgetProvider provider) {
    final amountCtrl = TextEditingController();
    int? selectedCatId;
    final expenseCats = provider.categories.where((c) => c.type == 'expense').toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16, right: 16, top: 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Задать лимит', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Категория расходов', border: OutlineInputBorder()),
              items: expenseCats.map((c) => DropdownMenuItem(
                value: c.id,
                child: Row(children: [
                  Icon(c.icon, color: c.color, size: 18),
                  const SizedBox(width: 8),
                  Text(c.name),
                ]),
              )).toList(),
              onChanged: (v) => setModal(() => selectedCatId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Лимит суммы', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                  if (amount == null || selectedCatId == null) return;
                  final now = provider.from;
                  await provider.upsertLimit(BudgetLimit(
                    categoryId: selectedCatId!,
                    month: now.month,
                    year: now.year,
                    limitAmount: amount,
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Сохранить'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
