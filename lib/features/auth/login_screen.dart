import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/department_enum.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black, // 배경색 확인
      body: Center(
        child: SingleChildScrollView( // 화면이 작을 때를 대비해 스크롤 추가
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

              // 버튼 리스트
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
    // [수정 핵심] Material 위젯을 사용하여 터치 효과(Ripple)와 이벤트를 보장합니다.
    return Material(
      color: Colors.transparent, // 배경 투명 (Ink가 색상 담당)
      child: InkWell(
        onTap: () {
          print("Login Button Tapped: ${dept.name}"); // 터치 확인용 로그

          // 로그인 로직 실행
          ref.read(authProvider.notifier).login(dept);

          // 라우터 리다이렉트가 자동으로 처리하지만, 혹시 모를 오류 방지를 위해 명시적 이동 시도
          // (라우터 설정이 완벽하면 아래 줄은 없어도 됩니다)
          // context.go('/home');
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: dept.color.withOpacity(0.3), // 터치 시 퍼지는 색상
        highlightColor: dept.color.withOpacity(0.1),
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            color: kCardColor, // 실제 버튼 배경색
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
      ),
    );
  }
}