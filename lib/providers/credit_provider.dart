import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ad_service.dart';

class CreditProvider extends ChangeNotifier {
  static const String _prefKeyCredits = 'divine_credits_balance';
  static const int _dailyFreeGrant = 3;
  static const int adRewardAmount = 3;

  int _balance = 0;
  bool _isLoading = true;

  int get balance => _balance;
  bool get isLoading => _isLoading;

  CreditProvider() {
    _loadCredits();
  }

  Future<void> _loadCredits() async {
    final prefs = await SharedPreferences.getInstance();
    _balance =
        prefs.getInt(_prefKeyCredits) ??
        _dailyFreeGrant; // Start with 3 for new users

    if (_balance == 0) {
      debugPrint('🔵 [CreditProvider] Balance is 0. Pre-loading ad.');
      AdService.instance.loadRewardedAd();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> consumeCredit({int cost = 1}) async {
    if (_balance >= cost) {
      _balance -= cost;

      if (_balance == 0) {
        debugPrint('🔵 [CreditProvider] Balance reached 0. Pre-loading ad.');
        AdService.instance.loadRewardedAd();
      }

      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyCredits, _balance);
    } else {
      throw Exception("Insufficient Divine Credits");
    }
  }

  Future<void> addCredits(int amount) async {
    _balance += amount;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyCredits, _balance);
  }

  bool hasCredit({int cost = 1}) {
    return _balance >= cost;
  }
}
