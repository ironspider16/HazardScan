import 'package:flutter/material.dart';

class AppLanguageManager {
  // Sets the default language to English for the session
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(const Locale('en'));

  static void changeLanguage(String languageCode) {
    localeNotifier.value = Locale(languageCode);
  }
}