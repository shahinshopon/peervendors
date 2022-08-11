import 'package:flutter/material.dart';

class AppSettings with ChangeNotifier {
  String locale;

  changeLocale(String langCode) {
    this.locale = langCode;
    notifyListeners();
  }
}