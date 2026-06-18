import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/transaction.dart' as m;
import '../models/plan.dart';
import '../models/group.dart';
import '../models/construction_section.dart';
import '../models/construction_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  static const _catBox       = 'categories';
  static const _txBox        = 'transactions';
  static const _planBox      = 'plans';
  static const _metaBox      = 'meta';
  static const _groupBox     = 'groups';
  static const _cSectionBox  = 'construction_sections';
  static const _cItemBox     = 'construction_items';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_catBox);
    await Hive.openBox<Map>(_txBox);
    await Hive.openBox<Map>(_planBox);
    await Hive.openBox<Map>(_groupBox);
    await Hive.openBox<Map>(_cSectionBox);
    await Hive.openBox<Map>(_cItemBox);
    await Hive.openBox(_metaBox);
    await _seedGroups();
    await _seedCategories();
    await _seedConstructionSections();
    await _migrateIcons();
    await _migrateGroupIds();
  }

  Box<Map> get _cats     => Hive.box<Map>(_catBox);
  Box<Map> get _txs      => Hive.box<Map>(_txBox);
  Box<Map> get _plans    => Hive.box<Map>(_planBox);
  Box<Map> get _groups   => Hive.box<Map>(_groupBox);
  Box<Map> get _cSects   => Hive.box<Map>(_cSectionBox);
  Box<Map> get _cItems   => Hive.box<Map>(_cItemBox);
  Box      get _meta     => Hive.box(_metaBox);

  int _nextId(String key) {
    final id = (_meta.get(key) as num?)?.toInt() ?? 0;
    _meta.put(key, id + 1);
    return id + 1;
  }

  // ── SEED GROUPS ─────────────────────────────────────
  Future<void> _seedGroups() async {
    if (_groups.isNotEmpty) return;
    final defaults = [
      {'name': 'Семейные расходы',   'icon': Icons.home.codePoint,             'color': 0xFF1565C0, 'sort_order': 1, 'type': 'expense'},
      {'name': 'Расходы на детей',   'icon': Icons.child_care.codePoint,       'color': 0xFFE91E63, 'sort_order': 2, 'type': 'expense'},
      {'name': 'Содержание авто',    'icon': Icons.directions_car.codePoint,   'color': 0xFFFF6F00, 'sort_order': 3, 'type': 'expense'},
      {'name': 'Строительство дома', 'icon': Icons.construction.codePoint,     'color': 0xFF4E342E, 'sort_order': 4, 'type': 'expense'},
      {'name': 'Доходы',             'icon': Icons.trending_up.codePoint,      'color': 0xFF2E7D32, 'sort_order': 5, 'type': 'income'},
    ];
    for (final d in defaults) {
      final id = _nextId('grp_id');
      await _groups.put(id, {...d, 'id': id});
    }
  }

  // ── SEED CATEGORIES ──────────────────────────────────
  Future<void> _seedCategories() async {
    if (_cats.isNotEmpty) return;
    final grpMap = _groupNameToId();
    final int semya   = grpMap['Семейные расходы']   ?? 1;
    final int deti    = grpMap['Расходы на детей']   ?? 2;
    final int avto    = grpMap['Содержание авто']    ?? 3;
    final int dohody  = grpMap['Доходы']             ?? 5;

    final defaults = [
      // Доходы
      {'name': 'Зарплата',       'type': 'income',  'color': 0xFF4CAF50, 'icon': Icons.work.codePoint,                  'group_id': dohody},
      {'name': 'Фриланс',        'type': 'income',  'color': 0xFF00BCD4, 'icon': Icons.laptop_mac.codePoint,            'group_id': dohody},
      {'name': 'Инвестиции',     'type': 'income',  'color': 0xFF8BC34A, 'icon': Icons.trending_up.codePoint,           'group_id': dohody},
      {'name': 'Подарки',        'type': 'income',  'color': 0xFFE91E63, 'icon': Icons.card_giftcard.codePoint,         'group_id': dohody},
      // Семейные расходы
      {'name': 'Продукты',       'type': 'expense', 'color': 0xFFFF9800, 'icon': Icons.local_grocery_store.codePoint,   'group_id': semya},
      {'name': 'ЖКХ',            'type': 'expense', 'color': 0xFF607D8B, 'icon': Icons.home.codePoint,                  'group_id': semya},
      {'name': 'Транспорт',      'type': 'expense', 'color': 0xFF2196F3, 'icon': Icons.directions_car.codePoint,        'group_id': semya},
      {'name': 'Развлечения',    'type': 'expense', 'color': 0xFF9C27B0, 'icon': Icons.movie.codePoint,                 'group_id': semya},
      {'name': 'Здоровье',       'type': 'expense', 'color': 0xFFF44336, 'icon': Icons.local_hospital.codePoint,        'group_id': semya},
      {'name': 'Одежда',         'type': 'expense', 'color': 0xFF795548, 'icon': Icons.checkroom.codePoint,             'group_id': semya},
      {'name': 'Рестораны',      'type': 'expense', 'color': 0xFFFF5722, 'icon': Icons.restaurant.codePoint,            'group_id': semya},
      {'name': 'Связь',          'type': 'expense', 'color': 0xFF00ACC1, 'icon': Icons.phone_android.codePoint,         'group_id': semya},
      // Расходы на детей
      {'name': 'Дети',           'type': 'expense', 'color': 0xFFFFEB3B, 'icon': Icons.child_care.codePoint,            'group_id': deti},
      {'name': 'Школа',          'type': 'expense', 'color': 0xFF5C6BC0, 'icon': Icons.school.codePoint,                'group_id': deti},
      {'name': 'Садик',          'type': 'expense', 'color': 0xFFEC407A, 'icon': Icons.toys.codePoint,                  'group_id': deti},
      {'name': 'Курсы',          'type': 'expense', 'color': 0xFF26A69A, 'icon': Icons.menu_book.codePoint,             'group_id': deti},
      // Содержание авто
      {'name': 'Топливо',        'type': 'expense', 'color': 0xFFF57C00, 'icon': Icons.local_gas_station.codePoint,     'group_id': avto},
      {'name': 'Ремонт авто',    'type': 'expense', 'color': 0xFF546E7A, 'icon': Icons.build.codePoint,                 'group_id': avto},
      {'name': 'Страховка авто', 'type': 'expense', 'color': 0xFF78909C, 'icon': Icons.security.codePoint,              'group_id': avto},
    ];
    for (final d in defaults) {
      final id = _nextId('cat_id');
      await _cats.put(id, {...d, 'id': id, 'parent_id': null});
    }
  }

  // ── SEED CONSTRUCTION SECTIONS ───────────────────────
  Future<void> _seedConstructionSections() async {
    if (_cSects.isNotEmpty) return;
    final sections = [
      {'name': 'Фундамент',       'plan_amount': 420000.0,  'icon': Icons.foundation.codePoint,    'color': 0xFF5D4037, 'sort_order': 1},
      {'name': 'Плита',           'plan_amount': 340000.0,  'icon': Icons.crop_square.codePoint,   'color': 0xFF795548, 'sort_order': 2},
      {'name': 'Стена',           'plan_amount': 900000.0,  'icon': Icons.domain.codePoint,        'color': 0xFF8D6E63, 'sort_order': 3},
      {'name': 'Колонна/Региль',  'plan_amount': 300000.0,  'icon': Icons.view_column.codePoint,   'color': 0xFF6D4C41, 'sort_order': 4},
      {'name': 'Крыша',           'plan_amount': 600000.0,  'icon': Icons.roofing.codePoint,       'color': 0xFF4E342E, 'sort_order': 5},
      {'name': 'Прочее',          'plan_amount': 150000.0,  'icon': Icons.more_horiz.codePoint,    'color': 0xFF757575, 'sort_order': 6},
      {'name': 'Авансы',          'plan_amount': 0.0,       'icon': Icons.payments.codePoint,      'color': 0xFF455A64, 'sort_order': 7},
    ];
    for (final d in sections) {
      final id = _nextId('csect_id');
      await _cSects.put(id, {...d, 'id': id});
    }
  }

  // ── MIGRATIONS ───────────────────────────────────────
  Future<void> _migrateIcons() async {
    if (_meta.get('icons_migrated_v2') == true) return;
    final fixes = <String, int>{
      'Зарплата': Icons.work.codePoint,           'Фриланс': Icons.laptop_mac.codePoint,
      'Инвестиции': Icons.trending_up.codePoint,  'Подарки': Icons.card_giftcard.codePoint,
      'Продукты': Icons.local_grocery_store.codePoint, 'ЖКХ': Icons.home.codePoint,
      'Транспорт': Icons.directions_car.codePoint,'Развлечения': Icons.movie.codePoint,
      'Здоровье': Icons.local_hospital.codePoint, 'Дети': Icons.child_care.codePoint,
      'Одежда': Icons.checkroom.codePoint,        'Рестораны': Icons.restaurant.codePoint,
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

  Future<void> _migrateGroupIds() async {
    if (_meta.get('group_ids_migrated_v1') == true) return;
    final grpMap = _groupNameToId();
    final semya  = grpMap['Семейные расходы']   ?? 1;
    final deti   = grpMap['Расходы на детей']   ?? 2;
    final avto   = grpMap['Содержание авто']    ?? 3;
    final dohody = grpMap['Доходы']             ?? 5;

    final mapping = <String, int>{
      'Зарплата': dohody,   'Фриланс': dohody,  'Инвестиции': dohody, 'Подарки': dohody,
      'Продукты': semya,    'ЖКХ': semya,       'Транспорт': semya,   'Развлечения': semya,
      'Здоровье': semya,    'Одежда': semya,     'Рестораны': semya,  'Связь': semya,
      'Дети': deti,         'Школа': deti,       'Садик': deti,       'Курсы': deti,
      'Топливо': avto,      'Ремонт авто': avto, 'Страховка авто': avto,
    };
    for (final key in _cats.keys) {
      final raw = _cats.get(key);
      if (raw == null) continue;
      final row = Map<String, dynamic>.from(raw);
      final name = row['name'] as String?;
      if (name != null && mapping.containsKey(name) && row['group_id'] == null) {
        await _cats.put(key, {...row, 'group_id': mapping[name]});
      }
    }
    await _meta.put('group_ids_migrated_v1', true);
  }

  Map<String, int> _groupNameToId() {
    final result = <String, int>{};
    for (final key in _groups.keys) {
      final raw = _groups.get(key);
      if (raw == null) continue;
      final row = Map<String, dynamic>.from(raw);
      final name = row['name'] as String?;
      final id   = (row['id'] as num?)?.toInt();
      if (name != null && id != null) result[name] = id;
    }
    return result;
  }

  // ── GROUPS CRUD ──────────────────────────────────────
  Future<List<Group>> getGroups() async {
    final rows = _groups.values
        .map((r) => Group.fromMap(Map<String, dynamic>.from(r)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return rows;
  }

  Future<int> insertGroup(Group g) async {
    final id = _nextId('grp_id');
    await _groups.put(id, {...g.toMap(), 'id': id});
    return id;
  }

  Future<void> updateGroup(Group g) async {
    await _groups.put(g.id, g.toMap());
  }

  Future<void> deleteGroup(int id) async {
    await _groups.delete(id);
  }

  // ── CATEGORIES CRUD ──────────────────────────────────
  Future<List<Category>> getCategories({String? type, int? groupId}) async {
    final rows = _cats.values
        .where((r) {
          if (type != null && r['type'] != type) return false;
          if (groupId != null && (r['group_id'] as num?)?.toInt() != groupId) return false;
          return true;
        })
        .map((r) => Category.fromMap(Map<String, dynamic>.from(r)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
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

  // ── TRANSACTIONS CRUD ────────────────────────────────
  Future<List<m.Transaction>> getTransactions({DateTime? from, DateTime? to, String? type}) async {
    final cats = {
      for (final r in _cats.values)
        (r['id'] as num).toInt(): Map<String, dynamic>.from(r)
    };
    return _txs.values
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
            'cat_group': cat?['group_id'],
          });
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
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

  // ── PLANS CRUD ───────────────────────────────────────
  Future<List<Plan>> getPlans({int? year, int? month, String? periodType}) async {
    final cats   = {for (final r in _cats.values)   (r['id'] as num).toInt(): Map<String, dynamic>.from(r)};
    final groups = {for (final r in _groups.values) (r['id'] as num).toInt(): Map<String, dynamic>.from(r)};
    return _plans.values
        .map((r) => Map<String, dynamic>.from(r))
        .where((r) {
          if (year       != null && (r['year'] as num?)?.toInt() != year)         return false;
          if (month      != null && (r['month'] as num?)?.toInt() != month)       return false;
          if (periodType != null && r['period_type'] != periodType)                return false;
          return true;
        })
        .map((r) {
          final catId = (r['category_id'] as num?)?.toInt();
          final grpId = (r['group_id'] as num?)?.toInt();
          return Plan.fromMap({
            ...r,
            'cat_name': catId != null ? (cats[catId] != null ? cats[catId]!['name'] : null) : null,
            'grp_name': grpId != null ? (groups[grpId] != null ? groups[grpId]!['name'] : null) : null,
          });
        })
        .toList();
  }

  Future<void> upsertPlan(Plan p) async {
    dynamic existing;
    for (final k in _plans.keys) {
      final r = _plans.get(k);
      if (r == null) continue;
      final sameCat   = (r['category_id'] as num?)?.toInt() == p.categoryId;
      final sameGrp   = (r['group_id'] as num?)?.toInt()    == p.groupId;
      final sameYear  = (r['year'] as num?)?.toInt()         == p.year;
      final sameMonth = (r['month'] as num?)?.toInt()        == p.month;
      final samePT    = r['period_type']                     == p.periodType;
      if (sameCat && sameGrp && sameYear && sameMonth && samePT) { existing = k; break; }
    }
    if (existing != null) {
      final old = Map<String, dynamic>.from(_plans.get(existing)!);
      await _plans.put(existing, {...old, 'amount': p.amount});
    } else {
      final id = _nextId('plan_id');
      await _plans.put(id, {...p.toMap(), 'id': id});
    }
  }

  Future<void> deletePlan(int id) async {
    await _plans.delete(id);
  }

  // ── CONSTRUCTION SECTIONS ────────────────────────────
  Future<List<ConstructionSection>> getConstructionSections() async {
    return _cSects.values
        .map((r) => ConstructionSection.fromMap(Map<String, dynamic>.from(r)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<int> insertConstructionSection(ConstructionSection s) async {
    final id = _nextId('csect_id');
    await _cSects.put(id, {...s.toMap(), 'id': id});
    return id;
  }

  Future<void> updateConstructionSection(ConstructionSection s) async {
    await _cSects.put(s.id, s.toMap());
  }

  Future<void> deleteConstructionSection(int id) async {
    await _cSects.delete(id);
    for (final k in List.from(_cItems.keys)) {
      final r = _cItems.get(k);
      if (r != null && (r['section_id'] as num?)?.toInt() == id) {
        await _cItems.delete(k);
      }
    }
  }

  // ── CONSTRUCTION ITEMS ───────────────────────────────
  Future<List<ConstructionItem>> getConstructionItems(int sectionId) async {
    return _cItems.values
        .where((r) => (r['section_id'] as num?)?.toInt() == sectionId)
        .map((r) => ConstructionItem.fromMap(Map<String, dynamic>.from(r)))
        .toList()
      ..sort((a, b) => (a.date ?? DateTime(2000)).compareTo(b.date ?? DateTime(2000)));
  }

  Future<Map<int, double>> getConstructionTotals() async {
    final result = <int, double>{};
    for (final r in _cItems.values) {
      final sid = (r['section_id'] as num?)?.toInt();
      if (sid == null) continue;
      result[sid] = (result[sid] ?? 0) + (r['amount'] as num).toDouble();
    }
    return result;
  }

  Future<int> insertConstructionItem(ConstructionItem item) async {
    final id = _nextId('citem_id');
    await _cItems.put(id, {...item.toMap(), 'id': id});
    return id;
  }

  Future<void> updateConstructionItem(ConstructionItem item) async {
    await _cItems.put(item.id, item.toMap());
  }

  Future<void> deleteConstructionItem(int id) async {
    await _cItems.delete(id);
  }

  // ── ANALYTICS ────────────────────────────────────────
  Future<Map<int, double>> getSumByCategory(String type, DateTime from, DateTime to) async {
    final result = <int, double>{};
    for (final r in _txs.values) {
      final row = Map<String, dynamic>.from(r);
      if (row['type'] != type) continue;
      final date = DateTime.parse(row['date'] as String);
      if (date.isBefore(from) || date.isAfter(to)) continue;
      final catId = (row['category_id'] as num).toInt();
      final amount = (row['amount'] as num).toDouble();
      result[catId] = (result[catId] ?? 0) + amount;
    }
    return result;
  }

  Future<Map<int, double>> getSumByGroup(String type, DateTime from, DateTime to) async {
    final catToGroup = <int, int>{};
    for (final r in _cats.values) {
      final catId = (r['id'] as num?)?.toInt();
      final grpId = (r['group_id'] as num?)?.toInt();
      if (catId != null && grpId != null) catToGroup[catId] = grpId;
    }
    final result = <int, double>{};
    for (final r in _txs.values) {
      final row = Map<String, dynamic>.from(r);
      if (row['type'] != type) continue;
      final date = DateTime.parse(row['date'] as String);
      if (date.isBefore(from) || date.isAfter(to)) continue;
      final catId = (row['category_id'] as num).toInt();
      final grpId = catToGroup[catId];
      if (grpId == null) continue;
      final amount = (row['amount'] as num).toDouble();
      result[grpId] = (result[grpId] ?? 0) + amount;
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotals(int months) async {
    final cutoff = DateTime.now().subtract(Duration(days: months * 31));
    final grouped = <String, Map<String, double>>{};
    for (final r in _txs.values) {
      final row  = Map<String, dynamic>.from(r);
      final date = DateTime.parse(row['date'] as String);
      if (date.isBefore(cutoff)) continue;
      final key  = '${date.year}-${date.month.toString().padLeft(2, '0')}';
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
