import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/group_card.dart';
import 'add_transaction_screen.dart';
import 'group_detail_screen.dart';

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

    final expGroups = provider.groups.where((g) => g.type != 'income').toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final incGroups = provider.groups.where((g) => g.type == 'income').toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

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
