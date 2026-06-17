import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../services/currency_service.dart';

class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});
  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await CurrencyService.instance.getRates(forceRefresh: true);
      if (mounted) {
        context.read<BudgetProvider>().loadRates(forceRefresh: true);
        setState(() {
          _error = result.error != null ? 'Не удалось загрузить с НБКР. Используются кешированные данные.' : null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<BudgetProvider>();
    final rates     = provider.rates;
    final lastDate  = CurrencyService.instance.lastUpdateDate;
    final numFmt    = NumberFormat('#,##0.00', 'ru_RU');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Курсы валют'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Обновить с НБКР',
              onPressed: _refresh,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Источник и дата ──
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.account_balance,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Национальный банк КР (НБКР)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                Text(
                  lastDate != null
                      ? 'Последнее обновление: $lastDate'
                      : 'Данные не загружены — нажмите ↻',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withAlpha(180)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: const TextStyle(color: Colors.orange, fontSize: 12)),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // ── KGS base ──
          _RateTile(
            flag: '🇰🇬',
            code: 'KGS',
            name: 'Кыргызский сом',
            rateText: 'Базовая валюта',
            valueText: '1.00',
            isBase: true,
          ),

          // ── Другие валюты ──
          for (final code in ['USD', 'EUR', 'RUB'])
            _RateTile(
              flag: CurrencyService.flags[code]!,
              code: code,
              name: CurrencyService.names[code]!,
              rateText: '1 $code =',
              valueText: '${numFmt.format(rates[code] ?? 0)} KGS',
            ),

          const SizedBox(height: 16),

          // ── Конвертер ──
          const _CurrencyConverter(),
        ],
      ),
    );
  }
}

class _RateTile extends StatelessWidget {
  final String flag;
  final String code;
  final String name;
  final String rateText;
  final String valueText;
  final bool isBase;

  const _RateTile({
    required this.flag,
    required this.code,
    required this.name,
    required this.rateText,
    required this.valueText,
    this.isBase = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Text(flag, style: const TextStyle(fontSize: 28)),
        title: Row(children: [
          Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isBase
                  ? const Color(0xFF4CAF50).withAlpha(30)
                  : const Color(0xFF4C1D95).withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isBase ? 'Базовая' : rateText,
              style: TextStyle(
                fontSize: 11,
                color: isBase ? const Color(0xFF4CAF50) : const Color(0xFF4C1D95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ]),
        subtitle: Text(name, style: const TextStyle(fontSize: 12)),
        trailing: Text(
          valueText,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isBase ? Colors.grey : const Color(0xFF1A0A40),
          ),
        ),
      ),
    );
  }
}

class _CurrencyConverter extends StatefulWidget {
  const _CurrencyConverter();
  @override
  State<_CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<_CurrencyConverter> {
  final _ctrl   = TextEditingController(text: '1');
  String _from  = 'USD';
  String _to    = 'KGS';

  double _convert(Map<String, double> rates) {
    final amount = double.tryParse(_ctrl.text.replaceAll(',', '.')) ?? 0;
    final fromRate = rates[_from] ?? 1;
    final toRate   = rates[_to]   ?? 1;
    return amount * fromRate / toRate;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final rates  = context.watch<BudgetProvider>().rates;
    final numFmt = NumberFormat('#,##0.####', 'ru_RU');
    final result = _convert(rates);
    final currencies = CurrencyService.supported;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Конвертер', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Сумма'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _from,
              items: currencies.map((c) => DropdownMenuItem(
                value: c,
                child: Text('${CurrencyService.flags[c]} $c'),
              )).toList(),
              onChanged: (v) => setState(() => _from = v!),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.arrow_downward, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              '${numFmt.format(result)} $_to',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _to,
              items: currencies.map((c) => DropdownMenuItem(
                value: c,
                child: Text('${CurrencyService.flags[c]} $c'),
              )).toList(),
              onChanged: (v) => setState(() => _to = v!),
            ),
          ]),
        ]),
      ),
    );
  }
}
