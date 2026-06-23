import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/plan.dart';
import '../models/group.dart';
import '../models/category.dart';
import '../models/construction_item.dart';
import '../providers/budget_provider.dart';
import '../models/construction_section.dart';
import '../models/construction_object.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});
  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  late int _year;
  late int _month;

  // ── icon / color palettes ──────────────────────────────────────────
  static const _iconOptions = [
    Icons.shopping_cart, Icons.restaurant, Icons.home, Icons.directions_car,
    Icons.school, Icons.local_hospital, Icons.fitness_center, Icons.movie,
    Icons.phone_android, Icons.flight, Icons.pets, Icons.attach_money,
    Icons.work, Icons.trending_up, Icons.savings, Icons.card_giftcard,
    Icons.child_care, Icons.sports_soccer, Icons.build, Icons.more_horiz,
  ];
  static const _colorOptions = [
    0xFFE53935, 0xFFD81B60, 0xFF8E24AA, 0xFF5E35B1,
    0xFF1E88E5, 0xFF039BE5, 0xFF00ACC1, 0xFF00897B,
    0xFF43A047, 0xFF7CB342, 0xFFF4511E, 0xFFFFB300,
    0xFF6D4C41, 0xFF546E7A, 0xFF455A64, 0xFF37474F,
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year  = now.year;
    _month = now.month;
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) { _month = 12; _year--; } else _month--;
    });
    context.read<BudgetProvider>().setMonth(_year, _month);
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) { _month = 1; _year++; } else _month++;
    });
    context.read<BudgetProvider>().setMonth(_year, _month);
  }

  // ── Plan dialog ──────────────────────────────────────────────────
  void _showPlanDialog(int? categoryId, int? groupId, double current) {
    final ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Установить план'),
        content: TextField(
          controller: ctrl, keyboardType: TextInputType.number, autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Сумма плана (KGS)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          if (current > 0)
            TextButton(
              onPressed: () async {
                final id = context.read<BudgetProvider>().plans
                    .where((p) => p.categoryId == categoryId && p.groupId == groupId
                        && p.year == _year && p.month == _month)
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
                categoryId: categoryId, groupId: groupId,
                amount: val, periodType: 'month', year: _year, month: _month,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  // ── Add category form ─────────────────────────────────────────────
  void _showAddCategoryForm(Group group) {
    final nameCtrl = TextEditingController();
    int selColor     = group.colorValue;
    IconData selIcon = group.icon;

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
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 14,
                    backgroundColor: group.color.withAlpha(30),
                    child: Icon(group.icon, color: group.color, size: 14)),
                const SizedBox(width: 10),
                Text('Новая статья · ${group.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, autofocus: true,
                  decoration: const InputDecoration(
                      labelText: 'Название статьи',
                      hintText: 'Продукты, Бензин, Одежда...',
                      border: OutlineInputBorder())),
              const SizedBox(height: 14),
              const Text('Цвет', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8,
                children: _colorOptions.map((c) => GestureDetector(
                  onTap: () => setModal(() => selColor = c),
                  child: Container(width: 32, height: 32,
                    decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle,
                      border: selColor == c
                          ? Border.all(color: Colors.black, width: 2.5) : null),
                  ),
                )).toList()),
              const SizedBox(height: 14),
              const Text('Иконка', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8,
                children: _iconOptions.map((ic) => GestureDetector(
                  onTap: () => setModal(() => selIcon = ic),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: selIcon == ic
                          ? Color(selColor).withAlpha(40) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: selIcon == ic
                          ? Border.all(color: Color(selColor), width: 2) : null,
                    ),
                    child: Icon(ic,
                        color: selIcon == ic
                            ? Color(selColor) : Colors.grey.shade500, size: 22),
                  ),
                )).toList()),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: group.color),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    await context.read<BudgetProvider>().addCategory(Category(
                      name:       name,
                      type:       group.type == 'income' ? 'income' : 'expense',
                      colorValue: selColor,
                      iconCode:   selIcon.codePoint,
                      groupId:    group.id,
                    ));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Добавить'),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Add construction object form ──────────────────────────────────
  void _showAddObjectForm(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

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
          const Text('Новый объект строительства',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl, autofocus: true,
            decoration: const InputDecoration(
                labelText: 'Название', hintText: 'Дом, Гараж, Дача...',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(
                labelText: 'Описание (необязательно)',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4A148C)),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                await context.read<BudgetProvider>().addConstructionObject(
                    ConstructionObject(
                      name: name,
                      description: descCtrl.text.trim().isEmpty
                          ? null : descCtrl.text.trim(),
                    ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Создать'),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ── Delete category ───────────────────────────────────────────────
  Future<void> _deleteCategory(Category cat) async {
    final provider = context.read<BudgetProvider>();
    final hasSpent = provider.spentForCategory(cat.id!) > 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить «${cat.name}»?'),
        content: Text(hasSpent
            ? 'У этой категории есть операции в текущем периоде. '
              'Категория будет удалена, операции останутся.'
            : 'Категория будет удалена без возможности восстановления.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await provider.deleteCategory(cat.id!);
    }
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
              IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white70),
                  onPressed: _prevMonth),
              Text(monthLabel[0].toUpperCase() + monthLabel.substring(1),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white70),
                  onPressed: _nextMonth),
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
              group:          g,
              categories:     provider.categoriesForGroup(g.id!),
              plans:          provider.plans,
              year:           _year,
              month:          _month,
              onEditPlan:     (catId, grpId, cur) => _showPlanDialog(catId, grpId, cur),
              onAddCategory:  () => _showAddCategoryForm(g),
              onDeleteCategory: (cat) => _deleteCategory(cat),
              spentForCat:    provider.spentForCategory,
            )),
          ],
          if (incGroups.isNotEmpty) ...[
            const SizedBox(height: 8),
            _sectionLabel('Доходы'),
            const SizedBox(height: 8),
            ...incGroups.map((g) => _GroupPlanCard(
              group:          g,
              categories:     provider.categoriesForGroup(g.id!),
              plans:          provider.plans,
              year:           _year,
              month:          _month,
              onEditPlan:     (catId, grpId, cur) => _showPlanDialog(catId, grpId, cur),
              onAddCategory:  () => _showAddCategoryForm(g),
              onDeleteCategory: (cat) => _deleteCategory(cat),
              spentForCat:    provider.spentForCategory,
            )),
          ],
          // ── Бюджет строительства ──────────────────────────────────────
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _sectionLabel('Бюджет строительства'),
              TextButton.icon(
                onPressed: () => _showAddObjectForm(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Добавить объект',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4A148C),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.cObjects.isEmpty)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24, horizontal: 16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.home_work_outlined,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Нет объектов строительства',
                      style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showAddObjectForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить первый объект'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4A148C),
                      side: const BorderSide(color: Color(0xFF4A148C)),
                    ),
                  ),
                ]),
              ),
            )
          else
            ...provider.cObjects.map((obj) => _ConstructionBudgetCard(
              object:   obj,
              sections: provider.sectionsForObject(obj.id!),
            )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: Color(0xFF777777), letterSpacing: 0.8));
}

// ── Group Plan Card ────────────────────────────────────────────────────────────
class _GroupPlanCard extends StatefulWidget {
  final Group group;
  final List<Category> categories;
  final List<Plan> plans;
  final int year;
  final int month;
  final void Function(int? categoryId, int? groupId, double current) onEditPlan;
  final VoidCallback onAddCategory;
  final Future<void> Function(Category) onDeleteCategory;
  final double Function(int) spentForCat;

  const _GroupPlanCard({
    required this.group,
    required this.categories,
    required this.plans,
    required this.year,
    required this.month,
    required this.onEditPlan,
    required this.onAddCategory,
    required this.onDeleteCategory,
    required this.spentForCat,
  });

  @override
  State<_GroupPlanCard> createState() => _GroupPlanCardState();
}

class _GroupPlanCardState extends State<_GroupPlanCard> {
  bool _expanded = true;

  double _planFor(int? catId) {
    final p = widget.plans.where((p) =>
        p.categoryId == catId && p.groupId == null &&
        p.year == widget.year && p.month == widget.month).firstOrNull;
    return p?.amount ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final fmt      = NumberFormat('#,##0', 'ru_RU');
    final total    = widget.categories
        .map((c) => _planFor(c.id))
        .fold(0.0, (s, v) => s + v);
    final grp      = widget.group;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [

        // ── Group header ──
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: grp.color,
            child: Row(children: [
              Icon(grp.icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(grp.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Text(
                total > 0 ? '${fmt.format(total)} KGS' : 'Нет плана',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 4),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70, size: 18),
            ]),
          ),
        ),

        // ── Categories ──
        if (_expanded) ...[
          if (widget.categories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text('Нет статей. Нажмите «+ Добавить статью» ниже.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center),
            )
          else ...[
            const Divider(height: 1),
            ...widget.categories.map((cat) {
              final catPlan = _planFor(cat.id);
              final spent   = widget.spentForCat(cat.id!);
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: cat.color.withAlpha(30),
                  child: Icon(cat.icon, color: cat.color, size: 14),
                ),
                title: Text(cat.name, style: const TextStyle(fontSize: 13)),
                subtitle: spent > 0
                    ? Text('Факт: ${fmt.format(spent)} KGS',
                        style: const TextStyle(fontSize: 11, color: Colors.grey))
                    : null,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    catPlan > 0 ? '${fmt.format(catPlan)} KGS' : '—',
                    style: TextStyle(fontSize: 13,
                        color: catPlan > 0 ? Colors.black87 : Colors.grey),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: Icon(catPlan > 0 ? Icons.edit : Icons.add_circle_outline,
                        size: 18, color: cat.color),
                    onPressed: () => widget.onEditPlan(cat.id, null, catPlan),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18,
                        color: spent > 0 ? Colors.grey.shade300 : Colors.redAccent),
                    tooltip: spent > 0 ? 'Есть операции в периоде' : 'Удалить статью',
                    onPressed: spent > 0 ? null : () => widget.onDeleteCategory(cat),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ]),
              );
            }),
          ],
          // ── Add category button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: OutlinedButton.icon(
              onPressed: widget.onAddCategory,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить статью', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: grp.color,
                side: BorderSide(color: grp.color),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

// ── Construction Budget Card ───────────────────────────────────────────────────
class _ConstructionBudgetCard extends StatefulWidget {
  final ConstructionObject object;
  final List<ConstructionSection> sections;

  const _ConstructionBudgetCard({required this.object, required this.sections});

  @override
  State<_ConstructionBudgetCard> createState() => _ConstructionBudgetCardState();
}

class _ConstructionBudgetCardState extends State<_ConstructionBudgetCard> {
  bool _expanded = true;
  final Map<int, bool> _secExpanded = {};

  static const _iconOptions = [
    Icons.foundation, Icons.crop_square, Icons.domain, Icons.view_column,
    Icons.roofing, Icons.window, Icons.door_front_door, Icons.plumbing,
    Icons.electrical_services, Icons.payments, Icons.more_horiz, Icons.build,
  ];
  static const _colorOptions = [
    0xFF5D4037, 0xFF795548, 0xFF8D6E63, 0xFF6D4C41,
    0xFF4E342E, 0xFF455A64, 0xFF546E7A, 0xFF37474F,
    0xFF1565C0, 0xFF2E7D32, 0xFF6A1B9A, 0xFF4A148C,
  ];

  void _showAddSectionForm(BuildContext context) {
    final nameCtrl = TextEditingController();
    int selColor     = _colorOptions[0];
    IconData selIcon = _iconOptions[0];

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
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Новая группа · ${widget.object.name}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, autofocus: true,
                  decoration: const InputDecoration(labelText: 'Название группы',
                      hintText: 'Фундамент, Электрика...', border: OutlineInputBorder())),
              const SizedBox(height: 14),
              const Text('Цвет', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _colorOptions.map((c) =>
                GestureDetector(
                  onTap: () => setModal(() => selColor = c),
                  child: Container(width: 32, height: 32,
                    decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle,
                      border: selColor == c
                          ? Border.all(color: Colors.black, width: 2.5) : null),
                  ),
                ),
              ).toList()),
              const SizedBox(height: 14),
              const Text('Иконка', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _iconOptions.map((ic) =>
                GestureDetector(
                  onTap: () => setModal(() => selIcon = ic),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: selIcon == ic
                          ? Color(selColor).withAlpha(40) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: selIcon == ic
                          ? Border.all(color: Color(selColor), width: 2) : null,
                    ),
                    child: Icon(ic,
                        color: selIcon == ic
                            ? Color(selColor) : Colors.grey.shade500, size: 22),
                  ),
                ),
              ).toList()),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final prov = context.read<BudgetProvider>();
                    await prov.addConstructionSection(ConstructionSection(
                      objectId:   widget.object.id!,
                      name:       name,
                      planAmount: 0,
                      iconCode:   selIcon.codePoint,
                      colorValue: selColor,
                      sortOrder:  widget.sections.length + 1,
                    ));
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

  void _showItemPlanDialog(BuildContext context, ConstructionItem item) {
    final ctrl = TextEditingController(
        text: item.planAmount > 0 ? item.planAmount.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('План: ${item.name}'),
        content: TextField(
          controller: ctrl, keyboardType: TextInputType.number, autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Плановая сумма (KGS)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          if (item.planAmount > 0)
            TextButton(
              onPressed: () async {
                await context.read<BudgetProvider>()
                    .updateConstructionItem(item.copyWith(planAmount: 0));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          FilledButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (val == null || val < 0) return;
              await context.read<BudgetProvider>()
                  .updateConstructionItem(item.copyWith(planAmount: val));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(BuildContext context, ConstructionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить статью?'),
        content: Text('«${item.name}» будет удалена.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<BudgetProvider>().deleteConstructionItem(item.id!);
    }
  }

  Future<void> _confirmDeleteObject(BuildContext context, BudgetProvider provider) async {
    final fact = provider.objectFact(widget.object.id!);
    final hasFact = fact > 0;
    final fmt = NumberFormat('#,##0', 'ru_RU');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить «${widget.object.name}»?'),
        content: hasFact
            ? Text(
                'На этот объект уже зафиксированы затраты: '
                '${fmt.format(fact)} KGS.\n\n'
                'При удалении будут удалены все группы, статьи '
                'и все записи расходов по этому объекту. '
                'Продолжить?',
              )
            : const Text(
                'Будут удалены все группы и статьи объекта. '
                'Это действие нельзя отменить.',
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.deleteConstructionObject(widget.object.id!);
    }
  }

  void _showAddPlanItemForm(BuildContext context, ConstructionSection section) {
    final nameCtrl = TextEditingController();
    final planCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16, right: 16, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 14,
              backgroundColor: section.color.withAlpha(30),
              child: Icon(section.icon, color: section.color, size: 14)),
            const SizedBox(width: 10),
            Text(section.name,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          TextField(controller: nameCtrl, autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Название статьи',
                  hintText: 'Арматура, Цемент, Работа...',
                  border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: planCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Плановая сумма (KGS)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final plan = double.tryParse(planCtrl.text.replaceAll(',', '.')) ?? 0;
                await context.read<BudgetProvider>().addConstructionItem(ConstructionItem(
                  sectionId: section.id!, name: name, planAmount: plan,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Добавить'),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt      = NumberFormat('#,##0', 'ru_RU');
    final provider = context.watch<BudgetProvider>();
    final total    = widget.sections.fold(0.0,
        (s, sec) => s + (provider.cPlanTotals[sec.id] ?? 0.0));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF4A148C),
            child: Row(children: [
              const Icon(Icons.home_work, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.object.name,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 14))),
              Text(total > 0 ? '${fmt.format(total)} KGS' : 'Нет бюджета',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.add_box_outlined, color: Colors.white70, size: 18),
                tooltip: 'Добавить группу',
                onPressed: () => _showAddSectionForm(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 18),
                tooltip: 'Удалить объект',
                onPressed: () => _confirmDeleteObject(context, provider),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70, size: 18),
            ]),
          ),
        ),
        if (_expanded) ...[
          if (widget.sections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: OutlinedButton.icon(
                onPressed: () => _showAddSectionForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Добавить первую группу'),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4A148C)),
              ),
            )
          else
            ...widget.sections.map((sec) {
              final secPlan = provider.cPlanTotals[sec.id] ?? 0.0;
              final fact    = provider.cTotals[sec.id] ?? 0.0;
              final items   = provider.itemsForSection(sec.id!);
              final secExp  = _secExpanded[sec.id] ?? false;

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Divider(height: 1),
                InkWell(
                  onTap: () => setState(() => _secExpanded[sec.id!] = !secExp),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      CircleAvatar(radius: 14,
                        backgroundColor: sec.color.withAlpha(30),
                        child: Icon(sec.icon, color: sec.color, size: 14)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(sec.name, style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                        if (fact > 0)
                          Text('Факт: ${fmt.format(fact)} KGS',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ])),
                      Text(secPlan > 0 ? '${fmt.format(secPlan)} KGS' : '—',
                          style: TextStyle(fontSize: 13,
                              color: secPlan > 0 ? Colors.black87 : Colors.grey)),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.playlist_add, size: 20,
                            color: Colors.grey.shade500),
                        tooltip: 'Добавить статью',
                        onPressed: () => _showAddPlanItemForm(context, sec),
                        padding: const EdgeInsets.only(left: 4),
                        constraints: const BoxConstraints(),
                      ),
                      Icon(secExp ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey, size: 18),
                    ]),
                  ),
                ),
                if (secExp) ...[
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 52, right: 16, bottom: 12),
                      child: Text('Нет статей. Нажмите ≡+ для добавления.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    )
                  else
                    ...items.map((item) {
                      final f = provider.cExpTotals[item.id] ?? 0.0;
                      return _ItemPlanTile(
                        item: item, factAmount: f, sec: sec,
                        onEdit: () => _showItemPlanDialog(context, item),
                        onDelete: f == 0 ? () => _deleteItem(context, item) : null,
                      );
                    }),
                  const SizedBox(height: 4),
                ],
              ]);
            }),
        ],
        const SizedBox(height: 4),
      ]),
    );
  }
}

// ── Item plan tile ─────────────────────────────────────────────────────────────
class _ItemPlanTile extends StatelessWidget {
  final ConstructionItem item;
  final double factAmount;
  final ConstructionSection sec;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ItemPlanTile({
    required this.item, required this.factAmount,
    required this.sec,  required this.onEdit, this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'ru_RU');
    return Container(
      color: Colors.grey.shade50,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 52, right: 12),
        title: Text(item.name, style: const TextStyle(fontSize: 12)),
        subtitle: factAmount > 0
            ? Text('Факт: ${fmt.format(factAmount)} KGS',
                style: const TextStyle(fontSize: 11, color: Colors.grey))
            : null,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            item.planAmount > 0 ? '${fmt.format(item.planAmount)} KGS' : '—',
            style: TextStyle(fontSize: 13,
                color: item.planAmount > 0 ? Colors.black87 : Colors.grey),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(item.planAmount > 0 ? Icons.edit : Icons.add_circle_outline,
                size: 18, color: sec.color),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 2),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
              tooltip: 'Удалить статью',
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ]),
      ),
    );
  }
}
