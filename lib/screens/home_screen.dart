import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/group_card.dart';
import 'add_transaction_screen.dart';
import 'group_detail_screen.dart';
import 'construction_object_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<BudgetProvider>();
    final fmt       = NumberFormat('#,##0', 'ru_RU');
    final monthName = DateFormat('MMMM yyyy', 'ru_RU').format(provider.from);
    final isCurrentMonth = provider.from.year == DateTime.now().year &&
                           provider.from.month == DateTime.now().month;

    final expGroups = provider.groups
        .where((g) => g.type != 'income' && provider.categoriesForGroup(g.id!).isNotEmpty)
        .toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final incGroups = provider.groups
        .where((g) => g.type == 'income' && provider.categoriesForGroup(g.id!).isNotEmpty)
        .toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 148,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1A237E),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, color: Colors.white70),
                              onPressed: () {
                                final d = provider.from;
                                provider.setMonth(d.year, d.month - 1);
                              },
                            ),
                            Text(
                              monthName[0].toUpperCase() + monthName.substring(1),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right,
                                  color: isCurrentMonth ? Colors.white24 : Colors.white70),
                              onPressed: isCurrentMonth ? null : () {
                                final d = provider.from;
                                provider.setMonth(d.year, d.month + 1);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.today, color: Colors.white54, size: 18),
                              onPressed: () {
                                final now = DateTime.now();
                                provider.setMonth(now.year, now.month);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _balanceChip('Доходы',  provider.totalIncome,   const Color(0xFF81C784), fmt),
                            _balanceChip('Расходы', provider.totalExpense,  const Color(0xFFEF9A9A), fmt),
                            _balanceChip('Остаток', provider.balance,       Colors.white,            fmt, large: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (expGroups.isNotEmpty) ...[
                  _sectionLabel('Расходы'),
                  const SizedBox(height: 8),
                  ...expGroups.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GroupCard(
                      group: g,
                      spent: provider.spentForGroup(g.id!),
                      plan: provider.planForGroup(g.id!),
                      categoryCount: provider.categoriesForGroup(g.id!).length,
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => GroupDetailScreen(group: g))),
                    ),
                  )),
                ],
                if (incGroups.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _sectionLabel('Доходы'),
                  const SizedBox(height: 8),
                  ...incGroups.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GroupCard(
                      group: g,
                      spent: provider.spentForGroup(g.id!),
                      plan: provider.planForGroup(g.id!),
                      categoryCount: provider.categoriesForGroup(g.id!).length,
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => GroupDetailScreen(group: g))),
                    ),
                  )),
                ],
                // ── Объекты строительства (fix 6) ──────────────
                if (provider.cObjects.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _sectionLabel('Строительство'),
                  const SizedBox(height: 8),
                  ...provider.cObjects.map((obj) {
                    final plan = provider.objectPlan(obj.id!);
                    final fact = provider.objectFact(obj.id!);
                    final hasPlan = plan > 0;
                    final over  = hasPlan && fact > plan;
                    final pct   = hasPlan ? (fact / plan).clamp(0.0, 1.0) : 0.0;
                    final pctLbl = hasPlan ? '${(fact / plan * 100).round()}%' : null;
                    final barCol = over ? const Color(0xFFD32F2F)
                        : (hasPlan && fact / plan > 0.8) ? const Color(0xFFF57F17)
                        : const Color(0xFF2E7D32);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ConstructionObjectScreen(object: obj))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: const Color(0xFF4A148C),
                              child: Row(children: [
                                const Icon(Icons.home_work, color: Colors.white, size: 22),
                                const SizedBox(width: 10),
                                Expanded(child: Text(obj.name,
                                    style: const TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.bold, fontSize: 15))),
                                if (pctLbl != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(40),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(pctLbl, style: const TextStyle(
                                        color: Colors.white, fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                  ),
                              ]),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Факт', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      Text(fmt.format(fact) + ' KGS',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                                              color: over ? const Color(0xFFD32F2F) : Colors.black87)),
                                    ])),
                                  if (hasPlan) Column(crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Бюджет', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      Text(fmt.format(plan) + ' KGS',
                                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                                    ]),
                                ]),
                                if (hasPlan) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct, minHeight: 6,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(barCol),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text('${provider.sectionsForObject(obj.id!).length} групп затрат',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_home',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
        backgroundColor: const Color(0xFF3949AB),
      ),
    );
  }

  Widget _balanceChip(String label, double amount, Color color, NumberFormat fmt, {bool large = false}) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      const SizedBox(height: 2),
      Text(
        '${fmt.format(amount)} KGS',
        style: TextStyle(
          color: color,
          fontSize: large ? 15 : 13,
          fontWeight: large ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ]);
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: Color(0xFF777777), letterSpacing: 0.8));
}
