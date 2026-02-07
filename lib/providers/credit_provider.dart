import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreditProvider extends ChangeNotifier {
  static const String _prefKeyCredits = 'divine_credits_balance';
  static const String _prefKeyLastGrantDate = 'divine_credits_last_grant';
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

    // Check for daily grant
    final lastGrantStr = prefs.getString(_prefKeyLastGrantDate);
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    // If never granted, set it to today so we don't double grant immediately
    if (lastGrantStr == null) {
      await prefs.setString(_prefKeyLastGrantDate, todayStr);
    } else if (lastGrantStr != todayStr) {
      // It's a new day! Grant daily credits.
      _grantDailyCredits(prefs, todayStr);
    }

    _isLoading = false;
    notifyListeners();
  }

  void _grantDailyCredits(SharedPreferences prefs, String todayStr) {
    if (_balance < _dailyFreeGrant) {
      // Logic: Top up to 5 if usage was heavy? Or just add 5?
      // Generous approach: Ensure they have AT LEAST 5 for the new day.
      // If they have 100 paid credits, we don't necessarily need to add 5 free ones,
      // but to be kind, let's just ADD 5 free tokens as a daily blessing.
      _balance += _dailyFreeGrant;
    } else {
      // If they have accumulated credits (e.g. bought pack), do we still give free?
      // Yes, "Daily Seva" is for everyone.
      _balance += _dailyFreeGrant;
    }

    prefs.setInt(_prefKeyCredits, _balance);
    prefs.setString(_prefKeyLastGrantDate, todayStr);
    notifyListeners();
  }

  Future<void> consumeCredit({int cost = 1}) async {
    if (_balance >= cost) {
      _balance -= cost;
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
