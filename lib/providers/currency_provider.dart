import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';

class CurrencyProvider extends ChangeNotifier {
  static const _prefKey = 'selected_currency_code';
  Currency _selected = Currency.all.first;

  Currency get selected => _selected;
  List<Currency> get all => Currency.all;

  CurrencyProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey) ?? 'INR';
    _selected = Currency.fromCode(code);
    notifyListeners();
  }

  Future<void> setCurrency(Currency c) async {
    _selected = c;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, c.code);
  }

  double convert(double inrAmount) => _selected.convert(inrAmount);

  /// Format a price stored in INR into the selected currency's display string.
  String format(double inrAmount) {
    final value = convert(inrAmount);
    final abs = value.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    String formatted;

    if (_selected.code == 'INR' && intPart.length > 3) {
      // Indian grouping: 1,23,456
      final last3 = intPart.substring(intPart.length - 3);
      final rest = intPart.substring(0, intPart.length - 3);
      final buf = StringBuffer();
      for (int i = 0; i < rest.length; i++) {
        if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
        buf.write(rest[i]);
      }
      formatted = '$buf,$last3';
    } else {
      // Western grouping: 123,456
      final buf = StringBuffer();
      final reversed = intPart.split('').reversed.toList();
      for (int i = 0; i < reversed.length; i++) {
        if (i > 0 && i % 3 == 0) buf.write(',');
        buf.write(reversed[i]);
      }
      formatted = buf.toString().split('').reversed.join();
    }

    final sign = value < 0 ? '-' : '';
    return '$sign${_selected.symbol}$formatted.$decPart';
  }
}