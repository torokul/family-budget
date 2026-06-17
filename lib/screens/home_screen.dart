import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/amount_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final monthFmt = DateFormat('MMMM yyyy', 'ru_RU');
    final recent = provider.transactions.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () {
              final d = provider.from;
              provider.setMonth(d.year, d.month - 1);
            },
          ),
          Text(monthFmt.format(provider.from), style: const TextStyle(fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () {
              final d = provider.from;
              provider.setMonth(d.year, d.month + 1);
            },
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              final now = DateTime.now();
              provider.setMonth(now.year, now.month);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.init,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Сводка ──
            Row(children: [
              Expanded(child: AmountCard(
                label: 'Доходы',
                amount: provider.totalIncome,
                color: const Color(0xFF4CAF50),
                icon: Icons.arrow_downward,
              )),
              const SizedBox(width: 8),
              Expanded(child: AmountCard(
                label: 'Расходы',
                amount: provider.totalExpense,
                color: const Color(0xFFF44336),
                icon: Icons.arrow_upward,
              )),
            ]),
            const SizedBox(height: 8),
            _BalanceCard(balance: provider.balance),
            const SizedBox(height: 16),

            // ── Лимиты ──
            if (provider.limits.isNotEmpty) ...[
              _SectionHeader(title: 'Лимиты бюджета', onMore: null),
              ...provider.limits.take(3).map((bl) {
                final spent = provider.spentForCategory(bl.categoryId);
                final pct = bl.limitAmount > 0 ? (spent / bl.limitAmount).clamp(0.0, 1.0) : 0.0;
                final over = spent > bl.limitAmount;
                final color = over ? const Color(0xFFF44336)
                    : pct > 0.8 ? const Color(0xFFFF9800) : const Color(0xFF4CAF50);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(bl.categoryName ?? '—',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                        if (over) const Icon(Icons.warning_amber, color: Color(0xFFF44336), size: 16),
                        Text(
                          '${NumberFormat('#,##0', 'ru_RU').format(spent)} / ${NumberFormat('#,##0', 'ru_RU').format(bl.limitAmount)}',
                          style: TextStyle(fontSize: 12, color: color),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct, minHeight: 6,
                          backgroundColor: Colors.grey.shade200, color: color,
                        ),
                      ),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            // ── Последние операции ──
            _SectionHeader(title: 'Последние операции', onMore: null),
            if (recent.isEmpty)
              const Card(child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('Нет операций', style: TextStyle(color: Colors.grey))),
              ))
            else
              ...recent.map((tx) => TransactionTile(
                tx: tx,
                onEdit: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: tx))),
                onDelete: () => provider.deleteTransaction(tx.id!),
              )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_home',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'ru_RU');
    final positive = balance >= 0;
    return Card(
      color: positive ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          const Icon(Icons.account_balance_wallet, color: Colors.white70),
          const SizedBox(width: 12),
          const Text('Баланс', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          Text(
            '${positive ? '+' : ''}${fmt.format(balance)}',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;
  const _SectionHeader({required this.title, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (onMore != null) TextButton(onPressed: onMore, child: const Text('Все')),
      ]),
    );
  }
}
