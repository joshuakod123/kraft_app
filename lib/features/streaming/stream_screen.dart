import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mini_player.dart';
import '../../core/state/global_providers.dart'; // [필수] 부서 색상 import

class StreamScreen extends ConsumerWidget {
  const StreamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // [수정] 현재 부서 색상 가져오기
    final dept = ref.watch(currentDeptProvider);
    final themeColor = dept.color;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // [수정] 배경 그라디언트를 부서 색상으로 변경
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.0,
                colors: [
                  themeColor.withValues(alpha: 0.2), // 부서별 색상 적용
                  Colors.black,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 60.0, left: 24, right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KRAFT MUSIC',
                    style: GoogleFonts.chakraPetch(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2
                    ),
                  ).animate().fadeIn().slideX(),

                  const SizedBox(height: 8),
                  Text(
                    'Streaming for Members',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),

                  const SizedBox(height: 40),

                  // 앨범 아트 (더미)
                  Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          // [수정] 그림자 색상도 부서 색상으로
                          BoxShadow(color: themeColor.withValues(alpha: 0.4), blurRadius: 40)
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ).animate().scale(duration: 1.seconds, curve: Curves.easeOutBack),
                  ),

                  const Spacer(),

                  // 미니 플레이어
                  const MiniPlayer(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}