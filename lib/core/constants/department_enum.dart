import 'package:flutter/material.dart';

// [1] 앱 전체에서 사용하는 배경색 및 카드 색상 상수 정의
const Color kAppBackgroundColor = Color(0xFF000000);
const Color kCardColor = Color(0xFF1E1E1E);

enum Department {
  business(
    id: 1, // DB ID와 매핑
    name: 'BUSINESS',
    icon: Icons.business_center,
    color: Color(0xFF00FF00),
  ),
  anr(
    id: 2,
    name: 'A&R',
    icon: Icons.album,
    color: Color(0xFFD900FF),
  ),
  music(
    id: 3,
    name: 'MUSIC',
    icon: Icons.music_note,
    color: Color(0xFF00E5FF),
  ),
  directing(
    id: 4,
    name: 'DIRECTING',
    icon: Icons.movie_creation,
    color: Color(0xFFFF3131),
  );

  final int id;
  final String name;
  final IconData icon;
  final Color color;

  const Department({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}