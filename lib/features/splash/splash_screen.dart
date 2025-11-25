import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/department_enum.dart';
import '../auth/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        final isLoggedIn = ref.read(authProvider);
        context.go(isLoggedIn ? '/home' : '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: AssetImage('assets/images/logo.png'), // 로고 파일명 확인
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    // [수정] 최신 문법 withValues 사용
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
            ).animate()
                .fadeIn(duration: 1000.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 3000.ms)
                .then(delay: 500.ms)
                .fadeOut(duration: 500.ms),

            const SizedBox(height: 40),

            const Text(
              'KRAFT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 800.ms),
          ],
        ),
      ),
    );
  }
}