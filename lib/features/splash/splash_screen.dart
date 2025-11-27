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
        child: Image.asset(
          'assets/images/logo.png',
          width: 200,
          height: 200,
        ).animate()
            .fadeIn(duration: 800.ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 2000.ms, curve: Curves.easeOutCubic),
      ),
    );
  }
}