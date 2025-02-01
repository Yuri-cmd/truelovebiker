import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color.fromRGBO(255, 0, 0, 1);
  static const Color btnColor = Color.fromRGBO(122, 161, 140, 1);
  static const Color title = Color.fromARGB(255, 0, 148, 94);
  static const Color bgContacto = Color.fromRGBO(0, 148, 94, 1);
  static final ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColor: primary,
    scaffoldBackgroundColor: primary,
    appBarTheme: const AppBarTheme(color: primary, elevation: 0),
  );
}
