import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/construction_object.dart';
import '../models/construction_section.dart';
import '../models/construction_item.dart';
import '../models/construction_expense.dart';
import '../providers/budget_provider.dart';
import '../services/currency_service.dart';

class ConstructionObjectScreen extends StatefulWidget {
  final ConstructionObject object;
  const ConstructionObjectScreen({super.key, required this.object});

  @override
  State<ConstructionObjectScreen> createState() => _ConstructionObjectScreenState();
}

class _ConstructionObjectScreenState extends State<ConstructionObjectScreen> {
  static const _units = ['шт', 'м', 'м²', 'м³', 'кг', 'т', 'л', 'уп', 'рул', 'мешок'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final fmt      = NumberFormat('#,##0', 'ru_RU');
    final sections = provider.sectionsForObject(widget.object.id!);
    final plan     = provider.objectPlan(widget.object.id!);
    final fact     = provider.objectFact(widget.object.id!);
    final over     = plan > 0 && fact > plan;
    final pct      = plan > 0 ? (fact / plan * 100).round() : null;
    final barCol   = over ? const Color(0xFFD32F2F)
        : (pct != null && pct > 80) ? const Color(0xFFF57F17) : const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF4A148C),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: const [],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFF4A148C),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 44, 16, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.home_work, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text(widget.object.name,
                            style: const TextStyle(color: Colors.white, fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _hdrCol('Бюджет',    plan,
                            Colors.white70, fmt),
                        _hdrCol('Потрачено', fact,
                            over ? const Color(0xFFEF9A9A) : const Color(0xFF81C784), fmt),
                        _hdrCol('Остаток',   plan - fact,
                            over ? const Color(0xFFEF9A9A) : const Color(0xFF81C784), fmt),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (plan > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (fact / plan).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(barCol),
                      ),
                    ),
                  ),
                if (sections.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(children: [
                        Icon(Icons.category_outlined, color: Colors.grey, size: 40),
                        SizedBox(height: 8),
                        Text('Нет групп затрат. Добавьте их во вкладке Планы.',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center),
                      ]),
                    ),
                  )
                else
                  ...sections.map((sec) => _SectionCard(
                    section: sec,
                    fmt: fmt,
                    onAddExpense: (item) => _showExpenseForm(context, item),
                  )),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hdrCol(String label, double val, Color color, NumberFormat fmt) =>
      Column(children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 3),
        Text(fmt.format(val),
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ]);

  // ── Expense form for a specific item ─────────────────────────────────────────
  void _showExpenseForm(BuildContext context, ConstructionItem item) {
    _openExpenseForm(context, item: item);
  }

  void _openExpenseForm(BuildContext context, {
    ConstructionItem? item,
    List<ConstructionSection>? sections,
  }) {
    final provider = context.read<BudgetProvider>();
    final qtyCtrl    = TextEditingController(text: '1');
    final priceCtrl  = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl   = TextEditingController();

    ConstructionSection? selSection = sections?.firstOrNull;
    ConstructionItem? selItem = item;
    if (selItem != null) {
      selSection = provider.cSections.where((s) => s.id == selItem!.sectionId).firstOrNull;
    }

    String selUnit     = item?.unit ?? 'шт';
    String selCurrency = 'KGS';
    DateTime? selDate  = DateTime.now();

    List<ConstructionItem> itemsForSection(ConstructionSection? sec) =>
        sec == null ? [] : provider.itemsForSection(sec.id!);

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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          qtyCtrl.addListener(() => recalc(setModal));
          priceCtrl.addListener(() => recalc(setModal));
          final secItems = itemsForSection(selSection);
          if (selItem != null && !secItems.contains(selItem)) selItem = null;

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16, right: 16, top: 20),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Добавить расход',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // Section picker (only when no pre-selected item)
                if (item == null && sections != null) ...[
                  DropdownButtonFormField<ConstructionSection>(
                    value: selSection,
                    decoration: const InputDecoration(
                        labelText: 'Группа затрат', border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined)),
                    items: sections.map((s) => DropdownMenuItem(
                      value: s,
                      child: Row(children: [
                        Icon(s.icon, color: s.color, size: 18),
                        const SizedBox(width: 8),
                        Text(s.name),
                      ]),
                    )).toList(),
                    onChanged: (v) => setModal(() {
                      selSection = v;
                      selItem = null;
                      selUnit = 'шт';
                    }),
                  ),
                  const SizedBox(height: 8),
                ],

                // Item picker (or fixed label if item pre-selected)
                if (item != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(children: [
                      const Icon(Icons.label_outline, color: Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      Text(item.name, style: const TextStyle(fontSize: 15)),
                    ]),
                  )
                else if (selSection != null) ...[
                  if (secItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Нет статей в группе «${selSection!.name}». '
                          'Добавьте статьи через вкладку Планы.',
                          style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                    )
                  else
                    DropdownButtonFormField<ConstructionItem>(
                      value: selItem,
                      decoration: const InputDecoration(
                          labelText: 'Статья затрат', border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label_outline)),
                      hint: const Text('Выберите статью'),
                      items: secItems.map((it) => DropdownMenuItem(
                        value: it,
                        child: Text(it.name),
                      )).toList(),
                      onChanged: (v) => setModal(() {
                        selItem = v;
                        selUnit = v?.unit ?? 'шт';
                      }),
                    ),
                ],
                const SizedBox(height: 8),

                // Date
                OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setModal(() => selDate = d);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(selDate != null
                      ? DateFormat('dd.MM.yyyy').format(selDate!) : 'Выбрать дату'),
                ),
                const SizedBox(height: 8),

                // Qty + unit + price
                Row(children: [
                  Expanded(flex: 3, child: TextField(
                    controller: qtyCtrl, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Кол-во', border: OutlineInputBorder()),
                  )),
                  const SizedBox(width: 6),
                  Expanded(flex: 3, child: DropdownButtonFormField<String>(
                    value: selUnit,
                    decoration: const InputDecoration(labelText: 'Ед.изм.',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
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

                // Amount (auto-calc)
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

                // Currency
                DropdownButtonFormField<String>(
                  value: selCurrency,
                  decoration: const InputDecoration(
                      labelText: 'Валюта', border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_exchange_outlined)),
                  items: CurrencyService.supported.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${CurrencyService.flags[c] ?? ''} $c'),
                  )).toList(),
                  onChanged: (v) { if (v != null) setModal(() => selCurrency = v); },
                ),
                const SizedBox(height: 8),

                TextField(controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Примечание', border: OutlineInputBorder())),
                const SizedBox(height: 16),

                SizedBox(width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final targetItem = item ?? selItem;
                      if (targetItem == null) return;
                      final qty   = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1;
                      final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
                      final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'))
                          ?? (qty * price);
                      if (amount <= 0) return;
                      await context.read<BudgetProvider>().addConstructionExpense(
                        ConstructionExpense(
                          itemId:      targetItem.id!,
                          qty:         qty,
                          unit:        selUnit,
                          price:       price,
                          amount:      amount,
                          currency:    selCurrency,
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          date:        selDate,
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
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatefulWidget {
  final ConstructionSection section;
  final NumberFormat fmt;
  final void Function(ConstructionItem) onAddExpense;

  const _SectionCard({
    required this.section,
    required this.fmt,
    required this.onAddExpense,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final sec      = widget.section;
    final plan     = provider.cPlanTotals[sec.id] ?? 0.0;
    final fact     = provider.cTotals[sec.id] ?? 0.0;
    final items    = provider.itemsForSection(sec.id!);
    final hasPlan  = plan > 0;
    final over     = hasPlan && fact > plan;
    final pct      = hasPlan ? (fact / plan * 100).round() : null;
    final barCol   = over ? const Color(0xFFD32F2F)
        : (pct != null && pct > 80) ? const Color(0xFFF57F17) : const Color(0xFF2E7D32);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // ── Section header ──
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: sec.color,
            child: Row(children: [
              Icon(sec.icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(sec.name, style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 14)),
                Row(children: [
                  Text(widget.fmt.format(fact),
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  if (hasPlan) ...[
                    const Text(' / ', style: TextStyle(color: Colors.white38)),
                    Text(widget.fmt.format(plan),
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                  const Text(' KGS', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ]),
              ])),
              if (pct != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$pct%', style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70, size: 18),
            ]),
          ),
        ),

        if (hasPlan)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (fact / plan).clamp(0.0, 1.0), minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(barCol),
              ),
            ),
          ),

        // ── Items ──
        if (_expanded) ...[
          const Divider(height: 1),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text('Нет статей. Добавьте через вкладку Планы.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            )
          else
            ...items.map((item) => _ItemCard(
              item: item,
              sec: sec,
              fmt: widget.fmt,
              onAddExpense: () => widget.onAddExpense(item),
            )),
        ],
      ]),
    );
  }
}

// ── Item Card ─────────────────────────────────────────────────────────────────
class _ItemCard extends StatefulWidget {
  final ConstructionItem item;
  final ConstructionSection sec;
  final NumberFormat fmt;
  final VoidCallback onAddExpense;

  const _ItemCard({
    required this.item,
    required this.sec,
    required this.fmt,
    required this.onAddExpense,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<BudgetProvider>();
    final item      = widget.item;
    final fact      = provider.cExpTotals[item.id] ?? 0.0;
    final plan      = item.planAmount;
    final hasPlan   = plan > 0;
    final over      = hasPlan && fact > plan;
    final expenses  = provider.expensesForItem(item.id!);

    final pct = hasPlan ? (fact / plan).clamp(0.0, 1.0) : 0.0;
    final barCol = over ? const Color(0xFFD32F2F)
        : (hasPlan && fact / plan > 0.8) ? const Color(0xFFF57F17)
        : const Color(0xFF2E7D32);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: widget.sec.color.withAlpha(80), width: 3),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Item header ──
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
                Row(children: [
                  Text(widget.fmt.format(fact),
                      style: TextStyle(fontSize: 12,
                          color: over ? const Color(0xFFD32F2F) : Colors.black54,
                          fontWeight: over ? FontWeight.bold : FontWeight.normal)),
                  if (hasPlan) ...[
                    Text(' / ${widget.fmt.format(plan)} KGS',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ] else
                    const Text(' KGS', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
                if (hasPlan) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct, minHeight: 4,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(barCol),
                    ),
                  ),
                ],
              ])),
              // Кнопка добавления расхода
              IconButton(
                icon: Icon(Icons.add_circle_outline,
                    color: widget.sec.color, size: 20),
                tooltip: 'Добавить расход',
                onPressed: widget.onAddExpense,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey, size: 18),
            ]),
          ),
        ),

        // ── Expenses (expanded) ──
        if (_expanded) ...[
          const Divider(height: 1, indent: 16),
          if (expenses.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 16, top: 6, bottom: 10),
              child: Text('Нет записей. Нажмите + в строке статьи для добавления расхода.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            )
          else
            ...expenses.map((exp) => _ExpenseTile(
              expense: exp,
              fmt: widget.fmt,
            )),
          const SizedBox(height: 4),
        ],
        const Divider(height: 1),
      ]),
    );
  }
}

// ── Expense Tile ──────────────────────────────────────────────────────────────
class _ExpenseTile extends StatelessWidget {
  final ConstructionExpense expense;
  final NumberFormat fmt;

  const _ExpenseTile({required this.expense, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final exp      = expense;
    final showQty  = exp.qty != 1 || exp.price != 0;
    final showCur  = exp.currency != 'KGS';

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 20, right: 12),
      leading: exp.date != null
          ? Column(mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(DateFormat('dd').format(exp.date!),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                        color: Colors.black54)),
                Text(DateFormat('MM.yy').format(exp.date!),
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ])
          : const Icon(Icons.receipt_long, size: 18, color: Colors.grey),
      title: Wrap(spacing: 6, children: [
        if (showQty)
          Text('${exp.qty % 1 == 0 ? exp.qty.toInt() : exp.qty} ${exp.unit}'
              '${exp.price > 0 ? ' × ${fmt.format(exp.price)}' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.black87)),
        if (showCur)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(exp.currency,
                style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
          ),
        if (exp.description != null)
          Text(exp.description!,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(fmt.format(exp.amount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        if (showCur)
          Text(' ${exp.currency}',
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ]),
    );
  }
}
