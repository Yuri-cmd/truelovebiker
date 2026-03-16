import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color.fromRGBO(255, 36, 36, 1);
  
  static final ThemeData lightTheme = ThemeData.light(useMaterial3: true).copyWith(
    primaryColor: primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
  );

  static final ThemeData darkTheme = ThemeData.dark(useMaterial3: true).copyWith(
    primaryColor: primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
  );
}
