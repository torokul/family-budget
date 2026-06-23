import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/transaction.dart' as m;
import '../models/plan.dart';
import '../models/group.dart';
import '../models/construction_object.dart';
import '../models/construction_section.dart';
import '../models/construction_item.dart';
import '../models/construction_expense.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  static const _catBox       = 'categories';
  static const _txBox        = 'transactions';
  static const _planBox      = 'plans';
  static const _metaBox      = 'meta';
  static const _groupBox     = 'groups';
  static const _cObjectBox   = 'construction_objects';
  static const _cSectionBox  = 'construction_sections';
  static const _cItemBox     = 'construction_items';
  static const _cExpBox      = 'construction_expenses';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_catBox);
    await Hive.openBox<Map>(_txBox);
    await Hive.openBox<Map>(_planBox);
    await Hive.openBox<Map>(_groupBox);
    await Hive.openBox<Map>(_cObjectBox);
    await Hive.openBox<Map>(_cSectionBox);
    await Hive.openBox<Map>(_cItemBox);
    await Hive.openBox<Map>(_cExpBox);
    await Hive.openBox(_metaBox);
    await _seedGroups();
    await _seedCategories();
    await _seedConstructionObjects();
    await _seedConstructionSections();
    await _migrateIcons();
    await _migrateGroupIds();
    await _migrateConstructionObjectIds();
    await _migrateItemsToExpenses();
    await _removeConstructionGroup();
  }

  Box<Map> get _cats     => Hive.box<Map>(_catBox);
  Box<Map> get _txs      => Hive.box<Map>(_txBox);
  Box<Map> get _plans    => Hive.box<Map>(_planBox);
  Box<Map> get _groups   => Hive.box<Map>(_groupBox);
  Box<Map> get _cObjects => Hive.box<Map>(_cObjectBox);
  Box<Map> get _cSects   => Hive.box<Map>(_cSectionBox);
  Box<Map> get _cItems   => Hive.box<Map>(_cItemBox);
  Box<Map> get _cExps    => Hive.box<Map>(_cExpBox);
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
      {'name': 'Доходы',             'icon': Icons.trending_up.codePoint,      'color': 0xFF2E7D32, 'sort_order': 4, 'type': 'income'},
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
      {'name': 'Зарплата',       'type': 'income',  'color': 0xFF4CAF50, 'icon': Icons.work.codePoint,                  'group_id': dohody},
      {'name': 'Фриланс',        'type': 'income',  'color': 0xFF00BCD4, 'icon': Icons.laptop_mac.codePoint,            'group_id': dohody},
      {'name': 'Инвестиции',     'type': 'income',  'color': 0xFF8BC34A, 'icon': Icons.trending_up.codePoint,           'group_id': dohody},
      {'name': 'Подарки',        'type': 'income',  'color': 0xFFE91E63, 'icon': Icons.card_giftcard.codePoint,         'group_id': dohody},
      {'name': 'Продукты',       'type': 'expense', 'color': 0xFFFF9800, 'icon': Icons.local_grocery_store.codePoint,   'group_id': semya},
      {'name': 'ЖКХ',            'type': 'expense', 'color': 0xFF607D8B, 'icon': Icons.home.codePoint,                  'group_id': semya},
      {'name': 'Транспорт',      'type': 'expense', 'color': 0xFF2196F3, 'icon': Icons.directions_car.codePoint,        'group_id': semya},
      {'name': 'Развлечения',    'type': 'expense', 'color': 0xFF9C27B0, 'icon': Icons.movie.codePoint,                 'group_id': semya},
      {'name': 'Здоровье',       'type': 'expense', 'color': 0xFFF44336, 'icon': Icons.local_hospital.codePoint,        'group_id': semya},
      {'name': 'Одежда',         'type': 'expense', 'color': 0xFF795548, 'icon': Icons.checkroom.codePoint,             'group_id': semya},
      {'name': 'Рестораны',      'type': 'expense', 'color': 0xFFFF5722, 'icon': Icons.restaurant.codePoint,            'group_id': semya},
      {'name': 'Связь',          'type': 'expense', 'color': 0xFF00ACC1, 'icon': Icons.phone_android.codePoint,         'group_id': semya},
      {'name': 'Дети',           'type': 'expense', 'color': 0xFFFFEB3B, 'icon': Icons.child_care.codePoint,            'group_id': deti},
      {'name': 'Школа',          'type': 'expense', 'color': 0xFF5C6BC0, 'icon': Icons.school.codePoint,                'group_id': deti},
      {'name': 'Садик',          'type': 'expense', 'color': 0xFFEC407A, 'icon': Icons.toys.codePoint,                  'group_id': deti},
      {'name': 'Курсы',          'type': 'expense', 'color': 0xFF26A69A, 'icon': Icons.menu_book.codePoint,             'group_id': deti},
      {'name': 'Топливо',        'type': 'expense', 'color': 0xFFF57C00, 'icon': Icons.local_gas_station.codePoint,     'group_id': avto},
      {'name': 'Ремонт авто',    'type': 'expense', 'color': 0xFF546E7A, 'icon': Icons.build.codePoint,                 'group_id': avto},
      {'name': 'Страховка авто', 'type': 'expense', 'color': 0xFF78909C, 'icon': Icons.security.codePoint,              'group_id': avto},
    ];
    for (final d in defaults) {
      final id = _nextId('cat_id');
      await _cats.put(id, {...d, 'id': id, 'parent_id': null});
    }
  }

  // ── SEED CONSTRUCTION OBJECTS ─────────────────────────
  Future<void> _seedConstructionObjects() async {
    if (_cObjects.isNotEmpty) return;
    final id = _nextId('cobj_id');
    await _cObjects.put(id, {'id': id, 'name': 'Дом', 'description': null, 'is_active': 1, 'sort_order': 1});
  }

  // ── SEED CONSTRUCTION SECTIONS ───────────────────────
  Future<void> _seedConstructionSections() async {
    if (_cSects.isNotEmpty) return;
    int? objId;
    for (final k in _cObjects.keys) {
      final r = _cObjects.get(k);
      if (r != null) { objId = (r['id'] as num?)?.toInt(); break; }
    }
    objId ??= 1;
    final sections = [
      {'name': 'Фундамент',       'plan_amount': 0.0, 'icon': Icons.foundation.codePoint,    'color': 0xFF5D4037, 'sort_order': 1},
      {'name': 'Плита',           'plan_amount': 0.0, 'icon': Icons.crop_square.codePoint,   'color': 0xFF795548, 'sort_order': 2},
      {'name': 'Стена',           'plan_amount': 0.0, 'icon': Icons.domain.codePoint,        'color': 0xFF8D6E63, 'sort_order': 3},
      {'name': 'Колонна/Региль',  'plan_amount': 0.0, 'icon': Icons.view_column.codePoint,   'color': 0xFF6D4C41, 'sort_order': 4},
      {'name': 'Крыша',           'plan_amount': 0.0, 'icon': Icons.roofing.codePoint,       'color': 0xFF4E342E, 'sort_order': 5},
      {'name': 'Прочее',          'plan_amount': 0.0, 'icon': Icons.more_horiz.codePoint,    'color': 0xFF757575, 'sort_order': 6},
      {'name': 'Авансы',          'plan_amount': 0.0, 'icon': Icons.payments.codePoint,      'color': 0xFF455A64, 'sort_order': 7},
    ];
    for (final d in sections) {
      final id = _nextId('csect_id');
      await _cSects.put(id, {...d, 'id': id, 'object_id': objId});
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

  Future<void> _migrateConstructionObjectIds() async {
    if (_meta.get('csections_obj_migrated_v1') == true) return;
    int? defaultObjId;
    for (final k in _cObjects.keys) {
      final r = _cObjects.get(k);
      if (r != null) { defaultObjId = (r['id'] as num?)?.toInt(); break; }
    }
    if (defaultObjId == null) return;
    for (final k in _cSects.keys) {
      final r = _cSects.get(k);
      if (r == null) continue;
      final row = Map<String, dynamic>.from(r);
      if (row['object_id'] == null) {
        await _cSects.put(k, {...row, 'object_id': defaultObjId});
      }
    }
    await _meta.put('csections_obj_migrated_v1', true);
  }

  // Migrate old ConstructionItem records (with amount > 0) → ConstructionExpense
  Future<void> _migrateItemsToExpenses() async {
    if (_meta.get('citems_to_expenses_v1') == true) return;
    for (final key in _cItems.keys) {
      final r = _cItems.get(key);
      if (r == null) continue;
      final row = Map<String, dynamic>.from(r);
      final amount = (row['amount'] as num?)?.toDouble() ?? 0;
      if (amount <= 0) continue;
      final itemId = (row['id'] as num?)?.toInt();
      if (itemId == null) continue;
      final expId = _nextId('cexp_id');
      await _cExps.put(expId, {
        'id':          expId,
        'item_id':     itemId,
        'qty':         (row['qty'] as num?)?.toDouble() ?? 1,
        'unit':        row['unit'] as String? ?? 'шт',
        'price':       (row['price'] as num?)?.toDouble() ?? 0,
        'amount':      amount,
        'currency':    row['currency'] as String? ?? 'KGS',
        'description': row['description'],
        'date':        row['date'],
      });
    }
    await _meta.put('citems_to_expenses_v1', true);
  }

  Future<void> _removeConstructionGroup() async {
    if (_meta.get('remove_construction_group_v1') == true) return;
    for (final key in _groups.keys.toList()) {
      final raw = _groups.get(key);
      if (raw == null) continue;
      final row = Map<String, dynamic>.from(raw);
      if (row['name'] == 'Строительство дома') {
        final groupId = (row['id'] as num?)?.toInt();
        await _groups.delete(key);
        if (groupId != null) {
          for (final ck in _cats.keys.toList()) {
            final cr = _cats.get(ck);
            if (cr == null) continue;
            if ((cr['group_id'] as num?)?.toInt() == groupId) {
              await _cats.delete(ck);
            }
          }
        }
      }
    }
    await _meta.put('remove_construction_group_v1', true);
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

  // ── CONSTRUCTION OBJECTS ─────────────────────────────
  Future<List<ConstructionObject>> getConstructionObjects() async {
    return _cObjects.values
        .map((r) => ConstructionObject.fromMap(Map<String, dynamic>.from(r)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<int> insertConstructionObject(ConstructionObject obj) async {
    final id = _nextId('cobj_id');
    await _cObjects.put(id, {...obj.toMap(), 'id': id});
    return id;
  }

  Future<void> updateConstructionObject(ConstructionObject obj) async {
    await _cObjects.put(obj.id, obj.toMap());
  }

  Future<void> deleteConstructionObject(int id) async {
    await _cObjects.delete(id);
    final sectKeys = List.from(_cSects.keys.where((k) {
      final r = _cSects.get(k);
      return r != null && (r['object_id'] as num?)?.toInt() == id;
    }));
    for (final sk in sectKeys) {
      final sid = (_cSects.get(sk)?['id'] as num?)?.toInt();
      await _cSects.delete(sk);
      if (sid != null) await _deleteExpensesForSection(sid);
    }
  }

  // ── CONSTRUCTION SECTIONS ────────────────────────────
  Future<List<ConstructionSection>> getConstructionSections({int? objectId}) async {
    return _cSects.values
        .where((r) => objectId == null || (r['object_id'] as num?)?.toInt() == objectId)
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
    await _deleteExpensesForSection(id);
  }

  Future<void> _deleteExpensesForSection(int sectionId) async {
    final itemKeys = List.from(_cItems.keys.where((k) {
      final r = _cItems.get(k);
      return r != null && (r['section_id'] as num?)?.toInt() == sectionId;
    }));
    for (final ik in itemKeys) {
      final itemId = (_cItems.get(ik)?['id'] as num?)?.toInt();
      await _cItems.delete(ik);
      if (itemId != null) await _deleteExpensesForItem(itemId);
    }
  }

  // ── CONSTRUCTION ITEMS ───────────────────────────────
  Future<List<ConstructionItem>> getAllConstructionItems() async {
    return _cItems.values
        .map((r) => ConstructionItem.fromMap(Map<String, dynamic>.from(r)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<List<ConstructionItem>> getConstructionItems(int sectionId) async {
    return _cItems.values
        .where((r) => (r['section_id'] as num?)?.toInt() == sectionId)
        .map((r) => ConstructionItem.fromMap(Map<String, dynamic>.from(r)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
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
    await _deleteExpensesForItem(id);
  }

  // ── CONSTRUCTION EXPENSES ────────────────────────────
  Future<List<ConstructionExpense>> getAllConstructionExpenses() async {
    return _cExps.values
        .map((r) => ConstructionExpense.fromMap(Map<String, dynamic>.from(r)))
        .toList()
      ..sort((a, b) => (a.date ?? DateTime(2000)).compareTo(b.date ?? DateTime(2000)));
  }

  Future<List<ConstructionExpense>> getConstructionExpenses(int itemId) async {
    return _cExps.values
        .where((r) => (r['item_id'] as num?)?.toInt() == itemId)
        .map((r) => ConstructionExpense.fromMap(Map<String, dynamic>.from(r)))
        .toList()
      ..sort((a, b) => (a.date ?? DateTime(2000)).compareTo(b.date ?? DateTime(2000)));
  }

  Future<int> insertConstructionExpense(ConstructionExpense exp) async {
    final id = _nextId('cexp_id');
    await _cExps.put(id, {...exp.toMap(), 'id': id});
    return id;
  }

  Future<void> updateConstructionExpense(ConstructionExpense exp) async {
    await _cExps.put(exp.id, exp.toMap());
  }

  Future<void> deleteConstructionExpense(int id) async {
    await _cExps.delete(id);
  }

  Future<void> _deleteExpensesForItem(int itemId) async {
    final keys = List.from(_cExps.keys.where((k) {
      final r = _cExps.get(k);
      return r != null && (r['item_id'] as num?)?.toInt() == itemId;
    }));
    for (final k in keys) await _cExps.delete(k);
  }

  // ── CONSTRUCTION TOTALS (from expenses, via items→sections) ─────────────────
  Future<Map<int, double>> getConstructionTotals() async {
    final itemToSection = <int, int>{};
    for (final r in _cItems.values) {
      final id  = (r['id'] as num?)?.toInt();
      final sid = (r['section_id'] as num?)?.toInt();
      if (id != null && sid != null) itemToSection[id] = sid;
    }
    final result = <int, double>{};
    for (final r in _cExps.values) {
      final iid = (r['item_id'] as num?)?.toInt();
      if (iid == null) continue;
      final sid = itemToSection[iid];
      if (sid == null) continue;
      result[sid] = (result[sid] ?? 0) + (r['amount'] as num).toDouble();
    }
    return result;
  }

  Future<Map<int, double>> getExpenseTotals() async {
    final result = <int, double>{};
    for (final r in _cExps.values) {
      final iid = (r['item_id'] as num?)?.toInt();
      if (iid == null) continue;
      result[iid] = (result[iid] ?? 0) + (r['amount'] as num).toDouble();
    }
    return result;
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
