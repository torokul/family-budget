import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final txs = provider.transactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('История операций'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: provider.setTypeFilter,
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('Все')),
              PopupMenuItem(value: 'income', child: Text('Только доходы')),
              PopupMenuItem(value: 'expense', child: Text('Только расходы')),
            ],
          ),
        ],
      ),
      body: txs.isEmpty
          ? const Center(child: Text('Нет операций за выбранный период'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: txs.length,
              itemBuilder: (_, i) => TransactionTile(
                tx: txs[i],
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: txs[i])),
                ),
                onDelete: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Удалить операцию?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
                      ],
                    ),
                  );
                  if (ok == true) provider.deleteTransaction(txs[i].id!);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_transactions',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
