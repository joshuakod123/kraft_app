import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/department_enum.dart'; // kCardColor
import 'auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'KRAFT',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8, color: Colors.white),
              ).animate().fadeIn(duration: 800.ms).scale(),

              const SizedBox(height: 10),
              Text(
                  'MEDIA & ENTERTAINMENT GROUP',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], letterSpacing: 2)
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 60),
              const Text('SELECT YOUR DEPARTMENT', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(authProvider.notifier).login(dept);
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: dept.color.withOpacity(0.3), // 수정됨
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dept.color.withOpacity(0.5), width: 1.5), // 수정됨
            boxShadow: [BoxShadow(color: dept.color.withOpacity(0.15), blurRadius: 12)], // 수정됨
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(dept.icon, color: dept.color, size: 28),
              const SizedBox(width: 16),
              Text(
                  dept.name,
                  style: TextStyle(color: dept.color, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)
              ),
            ],
          ),
        ),
      ),
    );
  }
}