import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/plan.dart';
import '../models/group.dart';
import '../models/category.dart';
import '../providers/budget_provider.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});
  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year  = now.year;
    _month = now.month;
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) { _month = 12; _year--; }
      else _month--;
    });
    context.read<BudgetProvider>().setMonth(_year, _month);
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) { _month = 1; _year++; }
      else _month++;
    });
    context.read<BudgetProvider>().setMonth(_year, _month);
  }

  @override
  Widget build(BuildContext context) {
    final provider   = context.watch<BudgetProvider>();
    final monthLabel = DateFormat('MMMM yyyy', 'ru_RU').format(DateTime(_year, _month));
    final expGroups  = provider.groups.where((g) => g.type != 'income').toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final incGroups  = provider.groups.where((g) => g.type == 'income').toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Планирование'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white70), onPressed: _prevMonth),
              Text(monthLabel[0].toUpperCase() + monthLabel.substring(1),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white70), onPressed: _nextMonth),
            ]),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (expGroups.isNotEmpty) ...[
            _sectionLabel('Расходы'),
            const SizedBox(height: 8),
            ...expGroups.map((g) => _GroupPlanCard(
              group: g,
              categories: provider.categoriesForGroup(g.id!),
              plans: provider.plans,
              year: _year,
              month: _month,
              onEdit: (catId, groupId, current) =>
                  _showPlanDialog(context, catId, groupId, current, _year, _month),
            )),
          ],
          if (incGroups.isNotEmpty) ...[
            const SizedBox(height: 8),
            _sectionLabel('Доходы'),
            const SizedBox(height: 8),
            ...incGroups.map((g) => _GroupPlanCard(
              group: g,
              categories: provider.categoriesForGroup(g.id!),
              plans: provider.plans,
              year: _year,
              month: _month,
              onEdit: (catId, groupId, current) =>
                  _showPlanDialog(context, catId, groupId, current, _year, _month),
            )),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showPlanDialog(BuildContext context, int? categoryId, int? groupId,
      double current, int year, int month) {
    final ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Установить план'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Сумма плана (KGS)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          if (current > 0)
            TextButton(
              onPressed: () async {
                final id = context.read<BudgetProvider>().plans
                    .where((p) => p.categoryId == categoryId && p.groupId == groupId
                        && p.year == year && p.month == month)
                    .firstOrNull?.id;
                if (id != null) await context.read<BudgetProvider>().deletePlan(id);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          FilledButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (val == null || val <= 0) return;
              await context.read<BudgetProvider>().upsertPlan(Plan(
                categoryId: categoryId,
                groupId:    groupId,
                amount:     val,
                periodType: 'month',
                year:       year,
                month:      month,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: Color(0xFF777777), letterSpacing: 0.8));
}

// ─────────────────────────────────────────────────────
class _GroupPlanCard extends StatefulWidget {
  final Group group;
  final List<Category> categories;
  final List<Plan> plans;
  final int year;
  final int month;
  final void Function(int? categoryId, int? groupId, double current) onEdit;

  const _GroupPlanCard({
    required this.group,
    required this.categories,
    required this.plans,
    required this.year,
    required this.month,
    required this.onEdit,
  });

  @override
  State<_GroupPlanCard> createState() => _GroupPlanCardState();
}

class _GroupPlanCardState extends State<_GroupPlanCard> {
  bool _expanded = true;

  double _planFor(int? catId, int? grpId) {
    final p = widget.plans.where((p) =>
      p.categoryId == catId && p.groupId == grpId &&
      p.year == widget.year && p.month == widget.month
    ).firstOrNull;
    return p?.amount ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final fmt      = NumberFormat('#,##0', 'ru_RU');
    final catPlans = widget.categories.map((c) => _planFor(c.id, null)).fold(0.0, (s, v) => s + v);
    final grpPlan  = _planFor(null, widget.group.id);
    final totalPlan = catPlans > 0 ? catPlans : grpPlan;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // Header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: widget.group.color,
            child: Row(children: [
              Icon(widget.group.icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.group.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Text(
                totalPlan > 0 ? '${fmt.format(totalPlan)} KGS' : 'Нет плана',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 4),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.white70, size: 18),
            ]),
          ),
        ),
        // Group-level plan row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Icon(Icons.folder_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            const Expanded(child: Text('По группе', style: TextStyle(fontSize: 13, color: Colors.grey))),
            Text(grpPlan > 0 ? '${fmt.format(grpPlan)} KGS' : '—',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(grpPlan > 0 ? Icons.edit : Icons.add_circle_outline,
                  size: 18, color: widget.group.color),
              onPressed: () => widget.onEdit(null, widget.group.id, grpPlan),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
        ),
        // Categories
        if (_expanded && widget.categories.isNotEmpty) ...[
          const Divider(height: 1),
          ...widget.categories.map((cat) {
            final catPlan = _planFor(cat.id, null);
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: cat.color.withAlpha(30),
                child: Icon(cat.icon, color: cat.color, size: 14),
              ),
              title: Text(cat.name, style: const TextStyle(fontSize: 13)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(catPlan > 0 ? '${fmt.format(catPlan)} KGS' : '—',
                    style: TextStyle(fontSize: 13,
                        color: catPlan > 0 ? Colors.black87 : Colors.grey)),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(catPlan > 0 ? Icons.edit : Icons.add_circle_outline,
                      size: 18, color: cat.color),
                  onPressed: () => widget.onEdit(cat.id, null, catPlan),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            );
          }),
        ],
        const SizedBox(height: 4),
      ]),
    );
  }
}
