import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 로고 섹션
              const Text(
                'KRAFT',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Colors.white
                ),
              ).animate().fadeIn(duration: 800.ms).scale(),

              const SizedBox(height: 10),
              Text(
                'MEDIA & ENTERTAINMENT GROUP',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], letterSpacing: 2),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 60),

              const Text(
                'SELECT YOUR DEPARTMENT',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 20),

              // 2. 부서 선택 버튼 리스트
              ...Department.values.map((dept) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _DepartmentLoginButton(dept: dept),
              )).toList().animate(interval: 100.ms).slideX(begin: 0.2, end: 0).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentLoginButton extends ConsumerWidget {
  final Department dept;
  const _DepartmentLoginButton({required this.dept});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        // [State Update] 1. 전역 상태에 선택한 부서 저장
        ref.read(currentDeptProvider.notifier).state = dept;

        // [State Update] 2. 관리자 여부 임의 설정 (테스트용: Business팀은 관리자 권한 부여)
        ref.read(isManagerProvider.notifier).state = (dept == Department.business);

        // 3. 홈 화면으로 이동
        context.go('/home');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dept.color.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: dept.color.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 0,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(dept.icon, color: dept.color, size: 28),
            const SizedBox(width: 16),
            Text(
              dept.name,
              style: TextStyle(
                color: dept.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}