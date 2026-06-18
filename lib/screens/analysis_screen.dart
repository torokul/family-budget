import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/group.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final fmt      = NumberFormat('#,##0', 'ru_RU');
    final month    = DateFormat('MMMM yyyy', 'ru_RU').format(provider.from);

    return Scaffold(
      appBar: AppBar(
        title: Text('Анализ · ${month[0].toUpperCase()}${month.substring(1)}'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          indicatorColor: const Color(0xFFD4A017),
          tabs: const [Tab(text: 'По группам'), Tab(text: 'По категориям')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _GroupAnalysis(provider: provider, fmt: fmt),
          _CategoryAnalysis(provider: provider, fmt: fmt),
        ],
      ),
    );
  }
}

// ── By Group ──────────────────────────────────────────────────────────────────
class _GroupAnalysis extends StatelessWidget {
  final BudgetProvider provider;
  final NumberFormat fmt;
  const _GroupAnalysis({required this.provider, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final groups = provider.groups
        .where((g) => g.type != 'income')
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (groups.isEmpty) {
      return const Center(child: Text('Нет данных', style: TextStyle(color: Colors.grey)));
    }

    final totalPlan  = groups.fold(0.0, (s, g) => s + provider.planForGroup(g.id!));
    final totalSpent = groups.fold(0.0, (s, g) => s + provider.spentForGroup(g.id!));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Summary card
        Card(
          color: const Color(0xFF1A237E),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _summaryChip('Итого план', totalPlan, Colors.white70, fmt),
              _summaryChip('Итого факт', totalSpent,
                  totalSpent > totalPlan ? const Color(0xFFEF9A9A) : const Color(0xFF81C784), fmt),
              _summaryChip('Отклонение', totalPlan - totalSpent,
                  (totalPlan - totalSpent) >= 0 ? const Color(0xFF81C784) : const Color(0xFFEF9A9A), fmt),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        ...groups.map((g) => _GroupRow(g: g, provider: provider, fmt: fmt)),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _summaryChip(String label, double val, Color color, NumberFormat fmt) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      const SizedBox(height: 4),
      Text(fmt.format(val), style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _GroupRow extends StatelessWidget {
  final Group g;
  final BudgetProvider provider;
  final NumberFormat fmt;
  const _GroupRow({required this.g, required this.provider, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final spent   = provider.spentForGroup(g.id!);
    final plan    = provider.planForGroup(g.id!);
    final hasPlan = plan > 0;
    final over    = hasPlan && spent > plan;
    final pct     = hasPlan ? (spent / plan * 100).round() : null;
    final barColor = over ? const Color(0xFFD32F2F)
        : (pct != null && pct > 80) ? const Color(0xFFF57F17) : const Color(0xFF2E7D32);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: g.color.withAlpha(30),
              child: Icon(g.icon, color: g.color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(g.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            if (pct != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: barColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$pct%', style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _factPlanChip('Факт', spent, over ? const Color(0xFFD32F2F) : Colors.black87, fmt),
            if (hasPlan) ...[
              _factPlanChip('План', plan, Colors.grey, fmt),
              _factPlanChip('Остаток', plan - spent,
                  over ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32), fmt),
            ],
          ]),
          if (hasPlan) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (spent / plan).clamp(0.0, 1.0), minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _factPlanChip(String label, double val, Color color, NumberFormat fmt) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      Text(fmt.format(val), style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ── By Category ───────────────────────────────────────────────────────────────
class _CategoryAnalysis extends StatelessWidget {
  final BudgetProvider provider;
  final NumberFormat fmt;
  const _CategoryAnalysis({required this.provider, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final cats = provider.categories.where((c) => c.type == 'expense').toList();

    if (cats.isEmpty) {
      return const Center(child: Text('Нет категорий', style: TextStyle(color: Colors.grey)));
    }

    final rows = cats.map((c) {
      final spent = provider.spentForCategory(c.id!);
      final plan  = provider.planForCategory(c.id!);
      return (cat: c, spent: spent, plan: plan);
    }).where((r) => r.spent > 0 || r.plan > 0).toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...rows.map((r) {
          final hasPlan = r.plan > 0;
          final over    = hasPlan && r.spent > r.plan;
          final pct     = hasPlan ? (r.spent / r.plan).clamp(0.0, 1.0) : 0.0;
          final barColor = over ? const Color(0xFFD32F2F)
              : (hasPlan && r.spent / r.plan > 0.8) ? const Color(0xFFF57F17) : r.cat.color;

          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: r.cat.color.withAlpha(30),
                    child: Icon(r.cat.icon, color: r.cat.color, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.cat.name, style: const TextStyle(fontSize: 13))),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(fmt.format(r.spent),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                            color: over ? const Color(0xFFD32F2F) : Colors.black87)),
                    if (hasPlan)
                      Text('/ ${fmt.format(r.plan)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
                ]),
                if (hasPlan) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct, minHeight: 5,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ],
              ]),
            ),
          );
        }),
        const SizedBox(height: 60),
      ],
    );
  }
}
