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
        // [수정됨] Notifier 메서드 호출 방식으로 변경
        ref.read(currentDeptProvider.notifier).setDept(dept);

        // 관리자 여부 설정
        ref.read(isManagerProvider.notifier).setManager(dept == Department.business);

        context.go('/home');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dept.color.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: dept.color.withValues(alpha: 0.15),
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