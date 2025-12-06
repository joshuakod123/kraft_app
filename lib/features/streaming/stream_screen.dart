import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mini_player.dart';

class StreamScreen extends StatelessWidget {
  const StreamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 배경 그라디언트
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.0,
                colors: [
                  Colors.indigoAccent.withValues(alpha: 0.2),
                  Colors.black,
                ],
              ),
            ),
          ),

          // [수정] SafeArea + Padding으로 UI를 아래로 내림
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 60.0, left: 24, right: 24), // 상단 여백 추가
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
                          BoxShadow(color: Colors.indigoAccent.withValues(alpha: 0.4), blurRadius: 40)
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
                  const SizedBox(height: 100), // 하단 탭바 가리지 않게 여백
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}