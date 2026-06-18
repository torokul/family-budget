import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../models/category.dart';
import '../providers/budget_provider.dart';
import 'add_transaction_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final provider   = context.watch<BudgetProvider>();
    final fmt        = NumberFormat('#,##0', 'ru_RU');
    final categories = provider.categoriesForGroup(group.id!);
    final groupSpent = provider.spentForGroup(group.id!);
    final groupPlan  = provider.planForGroup(group.id!);
    final hasPlan    = groupPlan > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: group.color,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: group.color,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
                    child: Row(children: [
                      Icon(group.icon, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(group.name,
                              style: const TextStyle(color: Colors.white, fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Text('Факт: ${fmt.format(groupSpent)} KGS',
                                style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            if (hasPlan) ...[
                              const Text('  /  ', style: TextStyle(color: Colors.white38)),
                              Text('План: ${fmt.format(groupPlan)} KGS',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ]),
                        ]),
                      ),
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
                if (hasPlan) ...[
                  _buildProgressBar(groupSpent, groupPlan, group.color),
                  const SizedBox(height: 12),
                ],
                if (categories.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Нет категорий в этой группе',
                          style: TextStyle(color: Colors.grey))),
                    ),
                  )
                else ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Категории', style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600, color: Color(0xFF777777), letterSpacing: 0.8)),
                  ),
                  ...categories.map((cat) => _CategoryRow(
                    category: cat,
                    spent: provider.spentForCategory(cat.id!),
                    plan: provider.planForCategory(cat.id!),
                    fmt: fmt,
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AddTransactionScreen(
                        preselectedCategoryId: cat.id,
                      ))),
                  )),
                ],
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_group_${group.id}',
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
        backgroundColor: group.color,
        icon: const Icon(Icons.add),
        label: const Text('Операция'),
      ),
    );
  }

  Widget _buildProgressBar(double spent, double plan, Color color) {
    final progress = (spent / plan).clamp(0.0, 1.0);
    final pct      = (spent / plan * 100).round();
    final over     = spent > plan;
    final barColor = over ? const Color(0xFFD32F2F)
        : pct > 80 ? const Color(0xFFF57F17) : const Color(0xFF2E7D32);
    final fmt = NumberFormat('#,##0', 'ru_RU');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Text('Итого по группе', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const Spacer(),
            Text('$pct%', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold,
                color: over ? const Color(0xFFD32F2F) : Colors.black87)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress, minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Факт: ${fmt.format(spent)} KGS', style: const TextStyle(fontSize: 12)),
            Text('Остаток: ${fmt.format(plan - spent)} KGS',
                style: TextStyle(fontSize: 12, color: over ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32))),
          ]),
        ]),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  final double spent;
  final double plan;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.category,
    required this.spent,
    required this.plan,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPlan  = plan > 0;
    final progress = hasPlan ? (spent / plan).clamp(0.0, 1.0) : 0.0;
    final over     = hasPlan && spent > plan;
    final barColor = over ? const Color(0xFFD32F2F)
        : (hasPlan && spent / plan > 0.8) ? const Color(0xFFF57F17)
        : const Color(0xFF2E7D32);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: category.color.withAlpha(30),
                child: Icon(category.icon, color: category.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(category.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fmt.format(spent),
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: over ? const Color(0xFFD32F2F) : Colors.black87,
                    )),
                if (hasPlan)
                  Text('из ${fmt.format(plan)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ]),
            ]),
            if (hasPlan) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress, minHeight: 5,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
