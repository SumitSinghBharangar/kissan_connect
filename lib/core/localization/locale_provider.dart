import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_translation.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale = 'en';

  String get locale => _locale;
  bool get isHindi => _locale == 'hi';

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString('selected_locale') ?? 'en';
    notifyListeners();
  }

  Future<void> setLocale(String langCode) async {
    if (_locale == langCode) return;
    _locale = langCode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', langCode);
  }

  // Translation helper function
  String tr(String key) {
    return AppTranslations.get(key, _locale);
  }
}
