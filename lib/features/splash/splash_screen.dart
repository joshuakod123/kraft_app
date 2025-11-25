import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/department_enum.dart'; // 색상 사용을 위해

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지 (글자는 이미지 안에 있다고 가정)
            Image.asset(
              'assets/images/logo.png',
              width: 180,
            ).animate()
                .fade(duration: 1000.ms)
                .scale(delay: 200.ms, duration: 800.ms, curve: Curves.easeOutBack),

            // [수정] 아래 텍스트 제거 (이미지에 포함되어 있으므로)
            // const SizedBox(height: 24),
            // const Text('KRAFT', ...),

            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ).animate().fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}