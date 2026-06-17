import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/transaction.dart' as m;
import '../models/budget_limit.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  static const _catBox  = 'categories';
  static const _txBox   = 'transactions';
  static const _limBox  = 'limits';
  static const _metaBox = 'meta';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_catBox);
    await Hive.openBox<Map>(_txBox);
    await Hive.openBox<Map>(_limBox);
    await Hive.openBox(_metaBox);
    await _seedIfEmpty();
    await _migrateIcons();
  }

  Box<Map> get _cats  => Hive.box<Map>(_catBox);
  Box<Map> get _txs   => Hive.box<Map>(_txBox);
  Box<Map> get _lims  => Hive.box<Map>(_limBox);
  Box    get _meta  => Hive.box(_metaBox);

  int _nextId(String key) {
    final id = (_meta.get(key) as num?)?.toInt() ?? 0;
    _meta.put(key, id + 1);
    return id + 1;
  }

  Future<void> _seedIfEmpty() async {
    if (_cats.isNotEmpty) return;
    final defaults = [
      {'name': 'Зарплата',    'type': 'income',  'color': 0xFF4CAF50, 'icon': Icons.work.codePoint},
      {'name': 'Фриланс',     'type': 'income',  'color': 0xFF00BCD4, 'icon': Icons.laptop_mac.codePoint},
      {'name': 'Инвестиции',  'type': 'income',  'color': 0xFF8BC34A, 'icon': Icons.trending_up.codePoint},
      {'name': 'Подарки',     'type': 'income',  'color': 0xFFE91E63, 'icon': Icons.card_giftcard.codePoint},
      {'name': 'Продукты',    'type': 'expense', 'color': 0xFFFF9800, 'icon': Icons.local_grocery_store.codePoint},
      {'name': 'ЖКХ',         'type': 'expense', 'color': 0xFF607D8B, 'icon': Icons.home.codePoint},
      {'name': 'Транспорт',   'type': 'expense', 'color': 0xFF2196F3, 'icon': Icons.directions_car.codePoint},
      {'name': 'Развлечения', 'type': 'expense', 'color': 0xFF9C27B0, 'icon': Icons.movie.codePoint},
      {'name': 'Здоровье',    'type': 'expense', 'color': 0xFFF44336, 'icon': Icons.local_hospital.codePoint},
      {'name': 'Дети',        'type': 'expense', 'color': 0xFFFFEB3B, 'icon': Icons.child_care.codePoint},
      {'name': 'Одежда',      'type': 'expense', 'color': 0xFF795548, 'icon': Icons.checkroom.codePoint},
      {'name': 'Рестораны',   'type': 'expense', 'color': 0xFFFF5722, 'icon': Icons.restaurant.codePoint},
    ];
    for (final d in defaults) {
      final id = _nextId('cat_id');
      await _cats.put(id, {...d, 'id': id, 'parent_id': null});
    }
  }

  // Исправляет иконки уже сохранённых стандартных категорий (однократно)
  Future<void> _migrateIcons() async {
    if (_meta.get('icons_migrated_v2') == true) return;

    final fixes = <String, int>{
      'Зарплата':    Icons.work.codePoint,
      'Фриланс':     Icons.laptop_mac.codePoint,
      'Инвестиции':  Icons.trending_up.codePoint,
      'Подарки':     Icons.card_giftcard.codePoint,
      'Продукты':    Icons.local_grocery_store.codePoint,
      'ЖКХ':         Icons.home.codePoint,
      'Транспорт':   Icons.directions_car.codePoint,
      'Развлечения': Icons.movie.codePoint,
      'Здоровье':    Icons.local_hospital.codePoint,
      'Дети':        Icons.child_care.codePoint,
      'Одежда':      Icons.checkroom.codePoint,
      'Рестораны':   Icons.restaurant.codePoint,
    };

    for (final key in _cats.keys) {
      final raw = _cats.get(key);
      if (raw == null) continue;
      final row = Map<String, dynamic>.from(raw);
      final name = row['name'] as String?;
      if (name != null && fixes.containsKey(name)) {
        await _cats.put(key, {...row, 'icon': fixes[name]});
      }
    }

    await _meta.put('icons_migrated_v2', true);
  }

  // ── Categories ──
  Future<List<Category>> getCategories({String? type}) async {
    final rows = _cats.values
        .where((r) => type == null || r['type'] == type)
        .map((r) => Category.fromMap(Map<String, dynamic>.from(r)))
        .toList();
    rows.sort((a, b) => a.name.compareTo(b.name));
    return rows;
  }

  Future<int> insertCategory(Category c) async {
    final id = _nextId('cat_id');
    await _cats.put(id, {...c.toMap(), 'id': id});
    return id;
  }

  Future<void> updateCategory(Category c) async {
    await _cats.put(c.id, c.toMap());
  }

  Future<void> deleteCategory(int id) async {
    await _cats.delete(id);
  }

  // ── Transactions ──
  Future<List<m.Transaction>> getTransactions({
    DateTime? from,
    DateTime? to,
    String? type,
  }) async {
    final cats = {for (final r in _cats.values) (r['id'] as num).toInt(): Map<String, dynamic>.from(r)};

    final rows = _txs.values
        .map((r) => Map<String, dynamic>.from(r))
        .where((r) {
          if (type != null && r['type'] != type) return false;
          final date = DateTime.parse(r['date'] as String);
          if (from != null && date.isBefore(from)) return false;
          if (to   != null && date.isAfter(to))   return false;
          return true;
        })
        .map((r) {
          final cat = cats[(r['category_id'] as num).toInt()];
          return m.Transaction.fromMap({
            ...r,
            'cat_name':  cat?['name'],
            'cat_color': cat?['color'],
            'cat_icon':  cat?['icon'],
          });
        })
        .toList();

    rows.sort((a, b) => b.date.compareTo(a.date));
    return rows;
  }

  Future<int> insertTransaction(m.Transaction t) async {
    final id = _nextId('tx_id');
    await _txs.put(id, {...t.toMap(), 'id': id});
    return id;
  }

  Future<void> updateTransaction(m.Transaction t) async {
    await _txs.put(t.id, t.toMap());
  }

  Future<void> deleteTransaction(int id) async {
    await _txs.delete(id);
  }

  // ── Budget limits ──
  Future<List<BudgetLimit>> getBudgetLimits(int month, int year) async {
    final cats = {for (final r in _cats.values) (r['id'] as num).toInt(): Map<String, dynamic>.from(r)};

    return _lims.values
        .map((r) => Map<String, dynamic>.from(r))
        .where((r) => r['month'] == month && r['year'] == year)
        .map((r) {
          final cat = cats[(r['category_id'] as num).toInt()];
          return BudgetLimit.fromMap({
            ...r,
            'cat_name':  cat?['name'],
            'cat_color': cat?['color'],
          });
        })
        .toList();
  }

  Future<void> upsertBudgetLimit(BudgetLimit bl) async {
    // Find existing for same category+month+year
    dynamic existing;
    for (final k in _lims.keys) {
      final r = _lims.get(k);
      if (r == null) continue;
      if ((r['category_id'] as num).toInt() == bl.categoryId &&
          (r['month'] as num).toInt() == bl.month &&
          (r['year'] as num).toInt() == bl.year) {
        existing = k;
        break;
      }
    }
    if (existing != null) {
      final old = Map<String, dynamic>.from(_lims.get(existing)!);
      await _lims.put(existing, {...old, 'limit_amount': bl.limitAmount});
    } else {
      final id = _nextId('lim_id');
      await _lims.put(id, {...bl.toMap(), 'id': id});
    }
  }

  Future<void> deleteBudgetLimit(int id) async {
    await _lims.delete(id);
  }

  // ── Analytics ──
  Future<Map<int, double>> getSumByCategory(String type, DateTime from, DateTime to) async {
    final result = <int, double>{};
    for (final r in _txs.values) {
      final row = Map<String, dynamic>.from(r);
      if (row['type'] != type) continue;
      final date = DateTime.parse(row['date'] as String);
      if (date.isBefore(from) || date.isAfter(to)) continue;
      final catId = row['category_id'] as int;
      final amount = (row['amount'] as num).toDouble();
      result[catId] = (result[catId] ?? 0) + amount;
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotals(int months) async {
    final cutoff = DateTime.now().subtract(Duration(days: months * 31));
    final grouped = <String, Map<String, double>>{};

    for (final r in _txs.values) {
      final row = Map<String, dynamic>.from(r);
      final date = DateTime.parse(row['date'] as String);
      if (date.isBefore(cutoff)) continue;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => {'income': 0, 'expense': 0});
      final amount = (row['amount'] as num).toDouble();
      if (row['type'] == 'income') {
        grouped[key]!['income'] = (grouped[key]!['income'] ?? 0) + amount;
      } else {
        grouped[key]!['expense'] = (grouped[key]!['expense'] ?? 0) + amount;
      }
    }

    return grouped.entries
        .map((e) => {'month': e.key, 'income': e.value['income'], 'expense': e.value['expense']})
        .toList()
      ..sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));
  }
}
