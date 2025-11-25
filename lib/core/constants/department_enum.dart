import 'package:flutter/material.dart';

// [1] 앱 전체에서 사용하는 배경색 및 카드 색상 상수 정의
const Color kAppBackgroundColor = Color(0xFF000000); // 완전 검정 혹은 아주 어두운 회색
const Color kCardColor = Color(0xFF1E1E1E); // 카드 배경색 (어두운 회색)

enum Department {
  business(
    name: 'BUSINESS',
    icon: Icons.business_center,
    color: Color(0xFF00FF00), // Neon Green
  ),
  anr(
    name: 'A&R',
    icon: Icons.album,
    color: Color(0xFFD900FF), // Neon Purple
  ),
  music(
    name: 'MUSIC',
    icon: Icons.music_note,
    color: Color(0xFF00E5FF), // Neon Cyan
  ),
  directing(
    name: 'DIRECTING',
    icon: Icons.movie_creation,
    color: Color(0xFFFF3131), // Neon Red
  );

  final String name;
  final IconData icon;
  final Color color;

  const Department({
    required this.name,
    required this.icon,
    required this.color,
  });
}