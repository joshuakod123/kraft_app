import 'package:flutter/material.dart';

// KRAFT 4대 부서 정의 (핵심 데이터)
enum Department {
  business(1, 'BUSINESS', Color(0xFF00FF00), Icons.analytics), // Neon Green
  anr(2, 'A&R', Color(0xFFD900FF), Icons.album),               // Neon Purple
  music(3, 'MUSIC', Color(0xFF00E5FF), Icons.graphic_eq),      // Neon Cyan
  directing(4, 'DIRECTING', Color(0xFFFF3131), Icons.videocam); // Neon Red

  final int id;
  final String name;
  final Color color;
  final IconData icon;

  const Department(this.id, this.name, this.color, this.icon);
}

// 앱 전역 디자인 상수
const Color kAppBackgroundColor = Color(0xFF121212); // 아주 짙은 회색
const Color kCardColor = Color(0xFF1E1E1E); // 카드 배경색