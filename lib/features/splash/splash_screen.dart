import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/department_enum.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 심플하게 이미지 하나만 표시 (박스 쉐도우 등 복잡한 효과 제거하여 안전성 확보)
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
            ).animate()
                .fadeIn(duration: 1000.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 2000.ms),

            // KRAFT 텍스트 제거됨
          ],
        ),
      ),
    );
  }
}