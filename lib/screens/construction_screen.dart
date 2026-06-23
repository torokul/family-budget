import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/construction_object.dart';
import '../models/construction_item.dart';
import '../models/construction_expense.dart';
import '../providers/budget_provider.dart';
import '../services/currency_service.dart';
import 'construction_object_screen.dart';

class ConstructionScreen extends StatelessWidget {
  const ConstructionScreen({super.key});

  static const _units = ['шт', 'м', 'м²', 'м³', 'кг', 'т', 'л', 'уп', 'рул', 'мешок'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final objects  = provider.cObjects;
    final fmt      = NumberFormat('#,##0', 'ru_RU');

    final totalPlan = objects.fold(0.0, (s, o) => s + provider.objectPlan(o.id!));
    final totalFact = objects.fold(0.0, (s, o) => s + provider.objectFact(o.id!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Строительство'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadConstruction(),
          ),
        ],
      ),
      body: objects.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.home_work_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Нет объектов строительства',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Добавьте объект во вкладке Планы',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              ]),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Summary (если > 1 объекта)
                if (objects.length > 1)
                  Card(
                    color: const Color(0xFF4A148C),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        const Row(children: [
                          Icon(Icons.construction, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text('Все объекты',
                              style: TextStyle(color: Colors.white, fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                          _col('Бюджет',    totalPlan, Colors.white70, fmt),
                          _col('Потрачено', totalFact,
                              totalFact > totalPlan
                                  ? const Color(0xFFEF9A9A) : const Color(0xFF81C784), fmt),
                          _col('Остаток',   totalPlan - totalFact,
                              (totalPlan - totalFact) >= 0
                                  ? const Color(0xFF81C784) : const Color(0xFFEF9A9A), fmt),
                        ]),
                      ]),
                    ),
                  ),

                ...objects.map((obj) {
                  final plan   = provider.objectPlan(obj.id!);
                  final fact   = provider.objectFact(obj.id!);
                  final sects  = provider.sectionsForObject(obj.id!);
                  final pct    = plan > 0 ? (fact / plan * 100).round() : null;
                  final over   = plan > 0 && fact > plan;
                  final barCol = over ? const Color(0xFFD32F2F)
                      : (pct != null && pct > 80) ? const Color(0xFFF57F17)
                      : const Color(0xFF2E7D32);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => ConstructionObjectScreen(object: obj))),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          color: const Color(0xFF4A148C),
                          child: Row(children: [
                            const Icon(Icons.home_work, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(obj.name,
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 16, fontWeight: FontWeight.bold)),
                                if (obj.description != null &&
                                    obj.description!.isNotEmpty)
                                  Text(obj.description!,
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 12)),
                              ]),
                            ),
                            if (pct != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(40),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('$pct%',
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.white70, size: 18),
                              tooltip: 'Изменить',
                              onPressed: () => _showObjectForm(context, obj),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: _factPlanCol('Бюджет', plan,
                                  Colors.black87, fmt)),
                              Expanded(child: _factPlanCol('Потрачено', fact,
                                  over ? const Color(0xFFD32F2F) : Colors.black87, fmt)),
                              Expanded(child: _factPlanCol('Остаток', plan - fact,
                                  over ? const Color(0xFFD32F2F)
                                      : const Color(0xFF2E7D32), fmt)),
                            ]),
                            if (plan > 0) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (fact / plan).clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(barCol),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text('${sects.length} групп затрат',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500)),
                          ]),
                        ),
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: objects.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab_construction',
              backgroundColor: const Color(0xFF4A148C),
              icon: const Icon(Icons.add_chart),
              label: const Text('Добавить расход'),
              onPressed: () => _showGlobalExpenseForm(context),
            ),
    );
  }

  // ── Глобальная форма добавления расхода ──────────────────────────────────────
  void _showGlobalExpenseForm(BuildContext context) {
    final provider = context.read<BudgetProvider>();
    final objects  = provider.cObjects;
    if (objects.isEmpty) return;

    final qtyCtrl    = TextEditingController(text: '1');
    final priceCtrl  = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl   = TextEditingController();

    ConstructionObject?  selObj     = objects.first;
    var selSections = provider.sectionsForObject(selObj.id!);
    var selSection  = selSections.isNotEmpty ? selSections.first : null;
    var selItems    = selSection != null
        ? provider.itemsForSection(selSection.id!) : <ConstructionItem>[];
    ConstructionItem? selItem = selItems.isNotEmpty ? selItems.first : null;

    String selUnit     = selItem?.unit ?? 'шт';
    String selCurrency = 'KGS';
    DateTime selDate   = DateTime.now();

    void recalc(StateSetter setModal) {
      final qty   = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 0;
      final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
      if (qty > 0 && price > 0) {
        amountCtrl.text = (qty * price).toStringAsFixed(0);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          qtyCtrl.addListener(() => recalc(setModal));
          priceCtrl.addListener(() => recalc(setModal));

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16, right: 16, top: 20),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Handle
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 14),
                const Text('Добавить расход',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                // ── Объект ──
                DropdownButtonFormField<ConstructionObject>(
                  value: selObj,
                  decoration: const InputDecoration(
                      labelText: 'Объект', border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home_work_outlined)),
                  items: objects.map((o) => DropdownMenuItem(
                    value: o, child: Text(o.name))).toList(),
                  onChanged: (o) => setModal(() {
                    selObj      = o;
                    selSections = o != null
                        ? provider.sectionsForObject(o.id!) : [];
                    selSection  = selSections.isNotEmpty ? selSections.first : null;
                    selItems    = selSection != null
                        ? provider.itemsForSection(selSection!.id!) : [];
                    selItem     = selItems.isNotEmpty ? selItems.first : null;
                    selUnit     = selItem?.unit ?? 'шт';
                  }),
                ),
                const SizedBox(height: 10),

                // ── Группа затрат ──
                if (selSections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'У объекта нет групп. Добавьте их в разделе Планы.',
                      style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                    ),
                  )
                else
                  DropdownButtonFormField(
                    value: selSection,
                    decoration: const InputDecoration(
                        labelText: 'Группа затрат', border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined)),
                    items: selSections.map((s) => DropdownMenuItem(
                      value: s,
                      child: Row(children: [
                        Icon(s.icon, color: s.color, size: 16),
                        const SizedBox(width: 8),
                        Text(s.name),
                      ]),
                    )).toList(),
                    onChanged: (s) => setModal(() {
                      selSection = s;
                      selItems   = s != null
                          ? provider.itemsForSection(s.id!) : [];
                      selItem    = selItems.isNotEmpty ? selItems.first : null;
                      selUnit    = selItem?.unit ?? 'шт';
                    }),
                  ),
                const SizedBox(height: 10),

                // ── Статья затрат ──
                if (selSection != null) ...[
                  if (selItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Нет статей в группе «${selSection!.name}». '
                        'Добавьте их в разделе Планы.',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                      ),
                    )
                  else
                    DropdownButtonFormField<ConstructionItem>(
                      value: selItem,
                      decoration: const InputDecoration(
                          labelText: 'Статья затрат', border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label_outline)),
                      items: selItems.map((it) => DropdownMenuItem(
                        value: it, child: Text(it.name))).toList(),
                      onChanged: (it) => setModal(() {
                        selItem = it;
                        selUnit = it?.unit ?? 'шт';
                      }),
                    ),
                ],
                const SizedBox(height: 10),

                // ── Дата ──
                OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setModal(() => selDate = d);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(DateFormat('dd.MM.yyyy').format(selDate)),
                ),
                const SizedBox(height: 10),

                // ── Кол-во × ед × цена ──
                Row(children: [
                  Expanded(flex: 3, child: TextField(
                    controller: qtyCtrl, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Кол-во', border: OutlineInputBorder()),
                  )),
                  const SizedBox(width: 6),
                  Expanded(flex: 3, child: DropdownButtonFormField<String>(
                    value: selUnit,
                    decoration: const InputDecoration(labelText: 'Ед.',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 14)),
                    items: _units.map((u) => DropdownMenuItem(
                        value: u, child: Text(u))).toList(),
                    onChanged: (v) { if (v != null) setModal(() => selUnit = v); },
                  )),
                  const SizedBox(width: 6),
                  Expanded(flex: 4, child: TextField(
                    controller: priceCtrl, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Цена', border: OutlineInputBorder()),
                  )),
                ]),
                const SizedBox(height: 8),

                // ── Сумма ──
                TextField(
                  controller: amountCtrl, keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Сумма (итого)',
                    border: const OutlineInputBorder(),
                    suffixIcon: Tooltip(
                      message: 'Авторасчёт: кол-во × цена',
                      child: Icon(Icons.calculate_outlined,
                          color: Colors.grey.shade400, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Валюта ──
                DropdownButtonFormField<String>(
                  value: selCurrency,
                  decoration: const InputDecoration(
                      labelText: 'Валюта', border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_exchange_outlined)),
                  items: CurrencyService.supported.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${CurrencyService.flags[c] ?? ''} $c'),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setModal(() => selCurrency = v);
                  },
                ),
                const SizedBox(height: 8),

                // ── Примечание ──
                TextField(controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Примечание', border: OutlineInputBorder())),
                const SizedBox(height: 16),

                // ── Сохранить ──
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4A148C)),
                    onPressed: () async {
                      if (selItem == null) return;
                      final qty    = double.tryParse(
                          qtyCtrl.text.replaceAll(',', '.')) ?? 1;
                      final price  = double.tryParse(
                          priceCtrl.text.replaceAll(',', '.')) ?? 0;
                      final amount = double.tryParse(
                          amountCtrl.text.replaceAll(',', '.'))
                          ?? (qty * price);
                      if (amount <= 0) return;
                      await context.read<BudgetProvider>().addConstructionExpense(
                        ConstructionExpense(
                          itemId:      selItem!.id!,
                          qty:         qty,
                          unit:        selUnit,
                          price:       price,
                          amount:      amount,
                          currency:    selCurrency,
                          description: descCtrl.text.trim().isEmpty
                              ? null : descCtrl.text.trim(),
                          date: selDate,
                        ),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Сохранить'),
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _col(String label, double val, Color color, NumberFormat fmt) =>
      Column(children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 3),
        Text(fmt.format(val),
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ]);

  Widget _factPlanCol(String label, double val, Color color, NumberFormat fmt) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(fmt.format(val),
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
      ]);

  void _showObjectForm(BuildContext context, ConstructionObject existing) {
    final nameCtrl = TextEditingController(text: existing.name);
    final descCtrl = TextEditingController(text: existing.description ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16, right: 16, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Изменить объект',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, autofocus: true,
              decoration: const InputDecoration(labelText: 'Название',
                  border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Описание',
                  border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                await context.read<BudgetProvider>().updateConstructionObject(
                    existing.copyWith(
                      name: name,
                      description: descCtrl.text.trim().isEmpty
                          ? null : descCtrl.text.trim(),
                    ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Сохранить'),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

}
