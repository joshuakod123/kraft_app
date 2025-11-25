import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/department_enum.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  // [수정] 여기에 있던 Timer와 context.go 로직을 모두 제거함.
  // 이제 이 화면은 단순히 보여지기만 하고, 이동은 AppRouter가 담당함.

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
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
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

            // [요청 반영] 텍스트 제거됨
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}