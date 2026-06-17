import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

class CurrencyService {
  static final CurrencyService instance = CurrencyService._();
  CurrencyService._();

  static const _boxName = 'currency_rates';
  static const _nbkrUrl = 'https://www.nbkr.kg/XML/daily.xml';

  static const supported = ['KGS', 'USD', 'EUR', 'RUB'];

  static const defaults = <String, double>{
    'KGS': 1.0,
    'USD': 89.24,
    'EUR': 96.80,
    'RUB': 0.98,
  };

  static const names = <String, String>{
    'KGS': 'Кыргызский сом',
    'USD': 'Доллар США',
    'EUR': 'Евро',
    'RUB': 'Российский рубль',
  };

  static const flags = <String, String>{
    'KGS': '🇰🇬',
    'USD': '🇺🇸',
    'EUR': '🇪🇺',
    'RUB': '🇷🇺',
  };

  Box get _box => Hive.box(_boxName);

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  String? get lastUpdateDate => _box.get('date') as String?;

  Map<String, double> getCached() {
    final result = <String, double>{'KGS': 1.0};
    for (final code in ['USD', 'EUR', 'RUB']) {
      final v = _box.get(code);
      if (v != null) result[code] = (v as num).toDouble();
    }
    if (result.length < 4) return {...defaults};
    return result;
  }

  Future<({Map<String, double> rates, bool fromCache, String? error})> getRates({
    bool forceRefresh = false,
  }) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = lastUpdateDate;

    if (!forceRefresh && savedDate == today && _box.containsKey('USD')) {
      return (rates: getCached(), fromCache: true, error: null);
    }

    try {
      final rates = await _fetchNBKR();
      for (final e in rates.entries) {
        await _box.put(e.key, e.value);
      }
      await _box.put('date', today);
      return (rates: rates, fromCache: false, error: null);
    } catch (e) {
      final cached = getCached();
      return (rates: cached, fromCache: true, error: e.toString());
    }
  }

  Future<Map<String, double>> _fetchNBKR() async {
    final response = await http
        .get(Uri.parse(_nbkrUrl))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final doc = XmlDocument.parse(response.body);
    final result = <String, double>{'KGS': 1.0};

    for (final el in doc.findAllElements('currency')) {
      final code = el.getAttribute('ISOCode');
      if (code == null || !['USD', 'EUR', 'RUB'].contains(code)) continue;

      final nominal = double.tryParse(
              el.findElements('nominal').firstOrNull?.innerText.trim() ?? '1') ??
          1;
      final value = double.tryParse(
              el.findElements('value').firstOrNull?.innerText
                      .trim()
                      .replaceAll(',', '.') ??
                  '0') ??
          0;

      if (value > 0) result[code] = value / nominal;
    }

    if (result.length < 4) throw Exception('Неполные данные от НБКР');
    return result;
  }
}
