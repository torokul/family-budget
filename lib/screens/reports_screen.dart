import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  late BudgetProvider _provider;
  Map<int, double> _expenseByCat = {};
  Map<int, double> _incomeByCat  = {};
  List<Map<String, dynamic>> _monthly = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<BudgetProvider>();
    _provider.removeListener(_onProviderUpdate);
    _provider.addListener(_onProviderUpdate);
    _loadData();
  }

  void _onProviderUpdate() => _loadData();

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final e = await _provider.getSumByCategory('expense');
    final i = await _provider.getSumByCategory('income');
    final m = await _provider.getMonthlyTotals();
    if (!mounted) return;
    setState(() {
      _expenseByCat = e;
      _incomeByCat  = i;
      _monthly      = m;
      _loading      = false;
    });
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final fmt = NumberFormat('#,##0', 'ru_RU');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчёты'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          indicatorColor: const Color(0xFFD4A017),
          tabs: const [Tab(text: 'Структура'), Tab(text: 'Динамика')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildPieTab(provider, fmt),
                _buildBarTab(fmt),
              ],
            ),
    );
  }

  Widget _buildPieTab(BudgetProvider provider, NumberFormat fmt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _pieSection('Расходы', _expenseByCat, provider, fmt, const Color(0xFFF44336)),
        const SizedBox(height: 24),
        _pieSection('Доходы', _incomeByCat, provider, fmt, const Color(0xFF4CAF50)),
      ]),
    );
  }

  Widget _pieSection(String title, Map<int, double> data,
      BudgetProvider provider, NumberFormat fmt, Color accent) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: Text('$title: нет данных за период',
              style: const TextStyle(color: Colors.grey))),
        ),
      );
    }

    final total = data.values.fold(0.0, (a, b) => a + b);
    final sections = data.entries.map((e) {
      final cat = provider.categories.where((c) => c.id == e.key).firstOrNull;
      final color = cat != null ? cat.color : Colors.grey;
      return PieChartSectionData(
        value: e.value,
        color: color,
        radius: 60,
        title: '${(e.value / total * 100).toStringAsFixed(1)}%',
        titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(fmt.format(total),
                style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            )),
          ),
          const Divider(height: 24),
          ...data.entries.map((e) {
            final cat = provider.categories.where((c) => c.id == e.key).firstOrNull;
            if (cat == null) return const SizedBox.shrink();
            final pct = e.value / total * 100;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Container(width: 12, height: 12,
                    decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8),
                Expanded(child: Text(cat.name, style: const TextStyle(fontSize: 13))),
                Text('${pct.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 8),
                Text(fmt.format(e.value),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildBarTab(NumberFormat fmt) {
    if (_monthly.isEmpty) {
      return const Center(child: Text('Недостаточно данных.\nДобавьте операции за несколько месяцев.',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
    }

    final maxY = _monthly.fold(0.0, (m, row) {
      final income  = (row['income']  as num?)?.toDouble() ?? 0;
      final expense = (row['expense'] as num?)?.toDouble() ?? 0;
      final v = income > expense ? income : expense;
      return v > m ? v : m;
    }) * 1.2;

    final groups = _monthly.asMap().entries.map((entry) {
      final i   = entry.key;
      final row = entry.value;
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: (row['income'] as num?)?.toDouble() ?? 0,
          color: const Color(0xFF4CAF50),
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: (row['expense'] as num?)?.toDouble() ?? 0,
          color: const Color(0xFFF44336),
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ], barsSpace: 4);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Text('Динамика по месяцам',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Row(children: const [
                SizedBox(width: 8),
                Icon(Icons.square, color: Color(0xFF4CAF50), size: 14),
                SizedBox(width: 4),
                Text('Доходы', style: TextStyle(fontSize: 12)),
                SizedBox(width: 12),
                Icon(Icons.square, color: Color(0xFFF44336), size: 14),
                SizedBox(width: 4),
                Text('Расходы', style: TextStyle(fontSize: 12)),
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(BarChartData(
                  barGroups: groups,
                  maxY: maxY > 0 ? maxY : 100,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (v, _) =>
                          Text(fmt.format(v), style: const TextStyle(fontSize: 10)),
                    )),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= _monthly.length) {
                          return const SizedBox.shrink();
                        }
                        return Text((_monthly[idx]['month'] as String).substring(5),
                            style: const TextStyle(fontSize: 10));
                      },
                    )),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
