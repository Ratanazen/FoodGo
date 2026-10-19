import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../core/utils/khmer_currency.dart';

enum DisplayCurrency { usd, khr, dual }

class CurrencyProvider with ChangeNotifier {
  static const String _prefKey = 'foodgo_preferred_currency';
  final ApiService _api = ApiService();

  DisplayCurrency _currency = DisplayCurrency.usd;
  double _khrPerUsd = 4100.0;
  String _rateSource = 'National Bank of Cambodia (NBC)';
  bool _isLoadingRate = false;

  DisplayCurrency get currency => _currency;
  double get khrPerUsd => _khrPerUsd;
  String get rateSource => _rateSource;
  bool get isLoadingRate => _isLoadingRate;

  bool get isUsd => _currency == DisplayCurrency.usd;
  bool get isKhr => _currency == DisplayCurrency.khr;
  bool get isDual => _currency == DisplayCurrency.dual;

  String get currencySymbol {
    switch (_currency) {
      case DisplayCurrency.usd:
        return r'$';
      case DisplayCurrency.khr:
        return '៛';
      case DisplayCurrency.dual:
        return r'$ / ៛';
    }
  }

  CurrencyProvider() {
    _loadPreferences();
    fetchLiveRate();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'khr') {
        _currency = DisplayCurrency.khr;
      } else if (saved == 'dual') {
        _currency = DisplayCurrency.dual;
      } else {
        _currency = DisplayCurrency.usd;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setCurrency(DisplayCurrency newCurrency) async {
    _currency = newCurrency;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String val = 'usd';
      if (newCurrency == DisplayCurrency.khr) {
        val = 'khr';
      } else if (newCurrency == DisplayCurrency.dual) {
        val = 'dual';
      }
      await prefs.setString(_prefKey, val);
    } catch (_) {}
  }

  void toggleCurrency() {
    if (_currency == DisplayCurrency.usd) {
      setCurrency(DisplayCurrency.khr);
    } else if (_currency == DisplayCurrency.khr) {
      setCurrency(DisplayCurrency.dual);
    } else {
      setCurrency(DisplayCurrency.usd);
    }
  }

  Future<void> fetchLiveRate() async {
    _isLoadingRate = true;
    notifyListeners();

    try {
      final data = await _api.get('currency/rates/');
      if (data != null && data['rate'] != null) {
        final parsed = double.tryParse(data['rate'].toString());
        if (parsed != null && parsed > 0) {
          _khrPerUsd = parsed;
          KhmerCurrency.updateRate(parsed, data['source']?.toString());
        }
        if (data['source'] != null) {
          _rateSource = data['source'].toString();
        }
      }
    } catch (_) {
      // Fallback to NBC customary 4,100 KHR / USD
    } finally {
      _isLoadingRate = false;
      notifyListeners();
    }
  }

  /// App-wide smart price formatter according to active currency preference
  String format(double usdAmount) {
    switch (_currency) {
      case DisplayCurrency.usd:
        return formatUsd(usdAmount);
      case DisplayCurrency.khr:
        return formatKhr(usdAmount);
      case DisplayCurrency.dual:
        return formatDual(usdAmount);
    }
  }

  String formatUsd(double usdAmount) {
    return '\$${usdAmount.toStringAsFixed(2)}';
  }

  String formatKhr(double usdAmount) {
    final khrVal = (usdAmount * _khrPerUsd).round();
    return '៛${_formatWithCommas(khrVal)}';
  }

  String formatDual(double usdAmount) {
    return '${formatUsd(usdAmount)} (${formatKhr(usdAmount)})';
  }

  int toKhr(double usdAmount) {
    return (usdAmount * _khrPerUsd).round();
  }

  double toUsd(double khrAmount) {
    return khrAmount / _khrPerUsd;
  }

  static String _formatWithCommas(int value) {
    final str = value.toString();
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(regex, (m) => '${m[1]},');
  }
}
