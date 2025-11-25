import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/department_enum.dart';

class AppTheme {
  static ThemeData getDynamicTheme(Department dept) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kAppBackgroundColor,
      primaryColor: dept.color,
      colorScheme: ColorScheme.dark(
        primary: dept.color,
        // [수정] withOpacity -> withValues
        secondary: dept.color.withValues(alpha: 0.8),
        surface: kCardColor,
        onPrimary: Colors.black,
      ),
      textTheme: GoogleFonts.chakraPetchTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}