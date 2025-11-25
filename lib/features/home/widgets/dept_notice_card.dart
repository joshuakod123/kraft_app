import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/department_enum.dart';

class DeptNoticeCard extends StatelessWidget {
  final Department dept;

  const DeptNoticeCard({super.key, required this.dept});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dept.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🔥 이번 주 정기 세션 안내",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "장소: 경영관 B103호\n시간: 금요일 18:00\n준비물: 개인 노트북 및 열정",
            style: TextStyle(color: Colors.grey[400], height: 1.5),
          ),
        ],
      ),
    ).animate().slideX(duration: 500.ms, curve: Curves.easeOut);
  }
}