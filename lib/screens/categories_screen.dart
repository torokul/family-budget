import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/budget_provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          indicatorColor: const Color(0xFFD4A017),
          tabs: const [Tab(text: 'Расходы'), Tab(text: 'Доходы')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(context, null, _tab.index == 0 ? 'expense' : 'income'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildList(provider.categories.where((c) => c.type == 'expense').toList(), context),
          _buildList(provider.categories.where((c) => c.type == 'income').toList(), context),
        ],
      ),
    );
  }

  Widget _buildList(List<Category> cats, BuildContext context) {
    if (cats.isEmpty) return const Center(child: Text('Нет категорий'));
    return ListView.builder(
      itemCount: cats.length,
      itemBuilder: (_, i) {
        final c = cats[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: c.color.withAlpha(30),
            child: Icon(c.icon, color: c.color),
          ),
          title: Text(c.name),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, c, c.type)),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () async {
                final prov = context.read<BudgetProvider>();
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Удалить категорию?'),
                    content: const Text('Транзакции этой категории останутся.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
                    ],
                  ),
                );
                if (ok == true) {
                  prov.deleteCategory(c.id!);
                }
              },
            ),
          ]),
        );
      },
    );
  }

  final _colorOptions = [
    0xFF4CAF50, 0xFFF44336, 0xFF2196F3, 0xFFFF9800, 0xFF9C27B0,
    0xFF00BCD4, 0xFF607D8B, 0xFFE91E63, 0xFF795548, 0xFFFFEB3B,
  ];

  final _iconOptions = <IconData>[
    // Финансы / доходы
    Icons.work,              Icons.laptop_mac,         Icons.trending_up,
    Icons.card_giftcard,     Icons.attach_money,        Icons.payments,
    Icons.account_balance,   Icons.currency_exchange,   Icons.savings,
    // Питание
    Icons.local_grocery_store, Icons.restaurant,        Icons.local_cafe,
    Icons.local_pizza,         Icons.set_meal,          Icons.bakery_dining,
    // Дом / ЖКХ
    Icons.home,              Icons.water_drop,          Icons.bolt,
    Icons.cleaning_services, Icons.weekend,             Icons.build,
    // Транспорт
    Icons.directions_car,    Icons.commute,             Icons.local_taxi,
    Icons.flight,            Icons.directions_bus,      Icons.pedal_bike,
    // Здоровье
    Icons.local_hospital,    Icons.medical_services,    Icons.healing,
    Icons.spa,               Icons.fitness_center,      Icons.medication,
    // Одежда / покупки
    Icons.checkroom,         Icons.shopping_bag,        Icons.shopping_cart,
    Icons.style,             Icons.watch,               Icons.diamond,
    // Развлечения
    Icons.movie,             Icons.sports_esports,      Icons.music_note,
    Icons.sports,            Icons.theater_comedy,      Icons.celebration,
    // Дети / образование
    Icons.child_care,        Icons.school,              Icons.toys,
    Icons.menu_book,         Icons.brush,               Icons.science,
    // Прочее
    Icons.pets,              Icons.travel_explore,      Icons.volunteer_activism,
    Icons.phone_android,     Icons.subscriptions,       Icons.more_horiz,
  ];

  void _showForm(BuildContext context, Category? existing, String type) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    int selectedColor = existing?.colorValue ?? _colorOptions[0];
    IconData selectedIcon = existing?.icon ?? _iconOptions[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(existing != null ? 'Изменить категорию' : 'Новая категория',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Цвет', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _colorOptions.map((c) => GestureDetector(
              onTap: () => setModal(() => selectedColor = c),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Color(c), shape: BoxShape.circle,
                  border: selectedColor == c ? Border.all(color: Colors.black, width: 2) : null,
                ),
              ),
            )).toList()),
            const SizedBox(height: 16),
            const Text('Иконка', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: _iconOptions.length,
                itemBuilder: (_, idx) {
                  final ic = _iconOptions[idx];
                  final selected = selectedIcon == ic;
                  return GestureDetector(
                    onTap: () => setModal(() => selectedIcon = ic),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected ? Color(selectedColor).withAlpha(40) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: selected ? Border.all(color: Color(selectedColor), width: 2) : null,
                      ),
                      child: Icon(ic,
                        color: selected ? Color(selectedColor) : Colors.grey.shade500,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final prov = context.read<BudgetProvider>();
                  final cat = Category(
                    id: existing?.id,
                    name: name,
                    type: type,
                    colorValue: selectedColor,
                    iconCode: selectedIcon.codePoint,
                  );
                  if (existing != null) {
                    await prov.updateCategory(cat);
                  } else {
                    await prov.addCategory(cat);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Сохранить'),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}
