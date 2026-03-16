import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    String? themePref = prefs.getString('themeMode');
    if (themePref == 'light') {
      value = ThemeMode.light;
    } else if (themePref == 'dark') {
      value = ThemeMode.dark;
    } else {
      value = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    String modeString = 'system';
    if (mode == ThemeMode.light) {
      modeString = 'light';
    } else if (mode == ThemeMode.dark) {
      modeString = 'dark';
    }
    await prefs.setString('themeMode', modeString);
  }
}

final ThemeNotifier themeNotifier = ThemeNotifier();
