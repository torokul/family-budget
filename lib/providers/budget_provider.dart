import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/category.dart';
import '../models/transaction.dart' as m;
import '../models/plan.dart';
import '../models/group.dart';
import '../models/construction_object.dart';
import '../models/construction_section.dart';
import '../models/construction_item.dart';
import '../models/construction_expense.dart';
import '../services/currency_service.dart';

class BudgetProvider extends ChangeNotifier {
  final _db  = DatabaseHelper.instance;
  final _cur = CurrencyService.instance;

  List<Group>              _groups       = [];
  List<Category>           _categories   = [];
  List<m.Transaction>      _transactions = [];
  List<Plan>               _plans        = [];
  List<ConstructionObject>  _cObjects     = [];
  List<ConstructionSection> _cSections   = [];
  List<ConstructionItem>    _cItems       = [];
  List<ConstructionExpense> _cExpenses   = [];
  Map<int, double>          _cTotals     = {};
  Map<int, double>          _cPlanTotals = {};
  Map<int, double>          _cExpTotals  = {};
  Map<String, double>      _rates        = CurrencyService.defaults;

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  String? _typeFilter;

  List<Group>              get groups       => _groups;
  List<Category>           get categories   => _categories;
  List<m.Transaction>      get transactions => _transactions;
  List<Plan>               get plans        => _plans;
  List<ConstructionObject>  get cObjects     => _cObjects;
  List<ConstructionSection> get cSections   => _cSections;
  List<ConstructionItem>    get cItems       => _cItems;
  List<ConstructionExpense> get cExpenses   => _cExpenses;
  Map<int, double>          get cTotals     => _cTotals;
  Map<int, double>          get cPlanTotals => _cPlanTotals;
  Map<int, double>          get cExpTotals  => _cExpTotals;
  Map<String, double>      get rates        => _rates;
  DateTime                 get from         => _from;
  DateTime                 get to           => _to;

  double toKgs(double amount, String currency) =>
      amount * (_rates[currency] ?? 1.0);

  double get totalIncome  => _transactions
      .where((t) => t.type == 'income')
      .fold(0, (s, t) => s + toKgs(t.amount, t.currency));

  double get totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (s, t) => s + toKgs(t.amount, t.currency));

  double get balance => totalIncome - totalExpense;

  Future<void> init() async {
    await loadRates();
    await loadGroups();
    await loadCategories();
    await loadTransactions();
    await loadPlans();
    await loadConstruction();
  }

  Future<void> loadRates({bool forceRefresh = false}) async {
    final result = await _cur.getRates(forceRefresh: forceRefresh);
    _rates = result.rates;
    notifyListeners();
  }

  Future<void> loadGroups() async {
    _groups = await _db.getGroups();
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categories = await _db.getCategories();
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _transactions = await _db.getTransactions(
        from: _from, to: _to, type: _typeFilter);
    notifyListeners();
  }

  Future<void> loadPlans() async {
    _plans = await _db.getPlans(
        year: _from.year, month: _from.month, periodType: 'month');
    notifyListeners();
  }

  Future<void> loadConstruction() async {
    _cObjects  = await _db.getConstructionObjects();
    _cSections = await _db.getConstructionSections();
    _cItems    = await _db.getAllConstructionItems();
    _cExpenses = await _db.getAllConstructionExpenses();
    _cTotals   = await _db.getConstructionTotals();
    _cExpTotals = {};
    for (final exp in _cExpenses) {
      _cExpTotals[exp.itemId] = (_cExpTotals[exp.itemId] ?? 0) + exp.amount;
    }
    _cPlanTotals = {};
    for (final item in _cItems) {
      _cPlanTotals[item.sectionId] = (_cPlanTotals[item.sectionId] ?? 0) + item.planAmount;
    }
    notifyListeners();
  }

  List<ConstructionSection> sectionsForObject(int objectId) =>
      _cSections.where((s) => s.objectId == objectId).toList();

  List<ConstructionItem> itemsForSection(int sectionId) =>
      _cItems.where((i) => i.sectionId == sectionId).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<ConstructionExpense> expensesForItem(int itemId) =>
      _cExpenses.where((e) => e.itemId == itemId).toList()
        ..sort((a, b) => (a.date ?? DateTime(2000)).compareTo(b.date ?? DateTime(2000)));

  double objectPlan(int objectId) {
    final secIds = sectionsForObject(objectId).map((s) => s.id).toSet();
    return _cPlanTotals.entries
        .where((e) => secIds.contains(e.key))
        .fold(0.0, (s, e) => s + e.value);
  }

  double objectFact(int objectId) {
    final secIds = sectionsForObject(objectId).map((s) => s.id).toSet();
    return _cTotals.entries
        .where((e) => secIds.contains(e.key))
        .fold(0, (s, e) => s + e.value);
  }

  void setMonth(int year, int month) {
    _from = DateTime(year, month, 1);
    _to   = DateTime(year, month + 1, 0, 23, 59, 59);
    loadTransactions();
    loadPlans();
  }

  void setTypeFilter(String? type) {
    _typeFilter = type;
    loadTransactions();
  }

  // ── Computed helpers ───────────────────────────────────

  List<Category> categoriesForGroup(int groupId) =>
      _categories.where((c) => c.groupId == groupId).toList();

  double spentForCategory(int categoryId) {
    final cat    = _categories.where((c) => c.id == categoryId).firstOrNull;
    final txType = (cat?.type == 'income') ? 'income' : 'expense';
    return _transactions
        .where((t) => t.type == txType && t.categoryId == categoryId)
        .fold(0, (s, t) => s + toKgs(t.amount, t.currency));
  }

  double spentForGroup(int groupId) {
    final group  = _groups.where((g) => g.id == groupId).firstOrNull;
    final txType = (group?.type == 'income') ? 'income' : 'expense';
    final catIds = categoriesForGroup(groupId).map((c) => c.id).toSet();
    return _transactions
        .where((t) => t.type == txType && catIds.contains(t.categoryId))
        .fold(0, (s, t) => s + toKgs(t.amount, t.currency));
  }

  double planForCategory(int categoryId) {
    final p = _plans.where((p) => p.categoryId == categoryId && p.groupId == null).firstOrNull;
    return p?.amount ?? 0;
  }

  double planForGroup(int groupId) {
    final catIds = categoriesForGroup(groupId).map((c) => c.id).toSet();
    final catTotal = _plans
        .where((p) => p.categoryId != null && catIds.contains(p.categoryId))
        .fold(0.0, (s, p) => s + p.amount);
    final grpPlan = _plans.where((p) => p.groupId == groupId && p.categoryId == null).firstOrNull;
    return catTotal > 0 ? catTotal : (grpPlan?.amount ?? 0);
  }

  // ── Transactions ──────────────────────────────────────
  Future<void> addTransaction(m.Transaction t) async {
    await _db.insertTransaction(t);
    await loadTransactions();
  }

  Future<void> updateTransaction(m.Transaction t) async {
    await _db.updateTransaction(t);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    await loadTransactions();
  }

  // ── Categories ────────────────────────────────────────
  Future<void> addCategory(Category c) async {
    await _db.insertCategory(c);
    await loadCategories();
  }

  Future<void> updateCategory(Category c) async {
    await _db.updateCategory(c);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    await loadCategories();
  }

  // ── Groups ────────────────────────────────────────────
  Future<void> addGroup(Group g) async {
    await _db.insertGroup(g);
    await loadGroups();
  }

  Future<void> updateGroup(Group g) async {
    await _db.updateGroup(g);
    await loadGroups();
  }

  Future<void> deleteGroup(int id) async {
    await _db.deleteGroup(id);
    await loadGroups();
  }

  // ── Plans ─────────────────────────────────────────────
  Future<void> upsertPlan(Plan p) async {
    await _db.upsertPlan(p);
    await loadPlans();
  }

  Future<void> deletePlan(int id) async {
    await _db.deletePlan(id);
    await loadPlans();
  }

  // ── Construction ──────────────────────────────────────
  Future<void> addConstructionItem(ConstructionItem item) async {
    await _db.insertConstructionItem(item);
    await loadConstruction();
  }

  Future<void> updateConstructionItem(ConstructionItem item) async {
    await _db.updateConstructionItem(item);
    await loadConstruction();
  }

  Future<void> deleteConstructionItem(int id) async {
    await _db.deleteConstructionItem(id);
    await loadConstruction();
  }

  Future<void> addConstructionObject(ConstructionObject obj) async {
    await _db.insertConstructionObject(obj);
    await loadConstruction();
  }

  Future<void> updateConstructionObject(ConstructionObject obj) async {
    await _db.updateConstructionObject(obj);
    await loadConstruction();
  }

  Future<void> deleteConstructionObject(int id) async {
    await _db.deleteConstructionObject(id);
    await loadConstruction();
  }

  Future<void> addConstructionSection(ConstructionSection s) async {
    await _db.insertConstructionSection(s);
    await loadConstruction();
  }

  Future<void> updateConstructionSection(ConstructionSection s) async {
    await _db.updateConstructionSection(s);
    await loadConstruction();
  }

  Future<void> deleteConstructionSection(int id) async {
    await _db.deleteConstructionSection(id);
    await loadConstruction();
  }

  // ── Construction Expenses ─────────────────────────────
  Future<void> addConstructionExpense(ConstructionExpense exp) async {
    await _db.insertConstructionExpense(exp);
    await loadConstruction();
  }

  Future<void> updateConstructionExpense(ConstructionExpense exp) async {
    await _db.updateConstructionExpense(exp);
    await loadConstruction();
  }

  Future<void> deleteConstructionExpense(int id) async {
    await _db.deleteConstructionExpense(id);
    await loadConstruction();
  }

  // ── Analytics ─────────────────────────────────────────
  Future<Map<int, double>> getSumByCategory(String type) async {
    final result = <int, double>{};
    for (final t in _transactions) {
      if (t.type != type) continue;
      result[t.categoryId] = (result[t.categoryId] ?? 0) + toKgs(t.amount, t.currency);
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotals() => _db.getMonthlyTotals(6);

  Future<List<m.Transaction>> fetchTransactions({
    DateTime? from, DateTime? to, String? type,
  }) => _db.getTransactions(from: from, to: to, type: type);
}
