import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/category.dart';
import '../models/transaction.dart' as m;
import '../models/budget_limit.dart';
import '../services/currency_service.dart';

class BudgetProvider extends ChangeNotifier {
  final _db  = DatabaseHelper.instance;
  final _cur = CurrencyService.instance;

  List<Category>     _categories   = [];
  List<m.Transaction> _transactions = [];
  List<BudgetLimit>  _limits       = [];
  Map<String, double> _rates       = CurrencyService.defaults;

  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  String? _typeFilter;

  List<Category>      get categories   => _categories;
  List<m.Transaction> get transactions => _transactions;
  List<BudgetLimit>   get limits       => _limits;
  Map<String, double> get rates        => _rates;
  DateTime            get from         => _from;
  DateTime            get to           => _to;

  double toKgs(double amount, String currency) =>
      amount * (_rates[currency] ?? 1.0);

  double get totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0, (s, t) => s + toKgs(t.amount, t.currency));

  double get totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (s, t) => s + toKgs(t.amount, t.currency));

  double get balance => totalIncome - totalExpense;

  Future<void> init() async {
    await loadRates();
    await loadCategories();
    await loadTransactions();
    await loadLimits();
  }

  Future<void> loadRates({bool forceRefresh = false}) async {
    final result = await _cur.getRates(forceRefresh: forceRefresh);
    _rates = result.rates;
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

  Future<void> loadLimits() async {
    _limits = await _db.getBudgetLimits(_from.month, _from.year);
    notifyListeners();
  }

  void setMonth(int year, int month) {
    _from = DateTime(year, month, 1);
    _to   = DateTime(year, month + 1, 0, 23, 59, 59);
    loadTransactions();
    loadLimits();
  }

  void setTypeFilter(String? type) {
    _typeFilter = type;
    loadTransactions();
  }

  // ── Transactions ──
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

  // ── Categories ──
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

  // ── Limits ──
  Future<void> upsertLimit(BudgetLimit bl) async {
    await _db.upsertBudgetLimit(bl);
    await loadLimits();
  }

  Future<void> deleteLimit(int id) async {
    await _db.deleteBudgetLimit(id);
    await loadLimits();
  }

  // ── Analytics ──
  Future<Map<int, double>> getSumByCategory(String type) async {
    // Re-compute from loaded transactions with currency conversion to KGS
    final result = <int, double>{};
    for (final t in _transactions) {
      if (t.type != type) continue;
      result[t.categoryId] =
          (result[t.categoryId] ?? 0) + toKgs(t.amount, t.currency);
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotals() async {
    return _db.getMonthlyTotals(6);
  }

  double spentForCategory(int categoryId) {
    return _transactions
        .where((t) => t.type == 'expense' && t.categoryId == categoryId)
        .fold(0, (s, t) => s + toKgs(t.amount, t.currency));
  }
}
