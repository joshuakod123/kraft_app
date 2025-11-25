import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/department_enum.dart';

class AppTheme {
  // 팀 컬러를 받아서 ThemeData를 생성하는 팩토리 메서드
  static ThemeData getDynamicTheme(Department dept) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kAppBackgroundColor,

      // 핵심: Primary Color를 팀 컬러로 강제 지정
      primaryColor: dept.color,

      // Material 3 Color Scheme
      colorScheme: ColorScheme.dark(
        primary: dept.color,
        secondary: dept.color.withValues(alpha: 0.8), // 수정됨
        surface: kCardColor,
        onPrimary: Colors.black, // 버튼 글씨는 검정색 (가독성)
      ),

      // 타이포그래피 (힙한 영문 폰트 + 깔끔한 한글 폰트 조합 권장)
      textTheme: GoogleFonts.chakraPetchTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),

      useMaterial3: true,

      // 앱바 테마
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}