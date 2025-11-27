import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui'; // Glass effect

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 현재 활성화된 탭 인덱스 계산
    final String location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/home')) currentIndex = 0;
    else if (location.startsWith('/upcoming')) currentIndex = 1;
    else if (location.startsWith('/archive')) currentIndex = 2;
    else if (location.startsWith('/stream')) currentIndex = 3;
    else if (location.startsWith('/profile')) currentIndex = 4;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true, // 바디를 네비게이션 바 뒤까지 확장
      body: Stack(
        children: [
          // 1. 메인 컨텐츠
          child,

          // 2. Floating Bottom Navigation Bar
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withValues(alpha: 0.85), // 반투명 검정
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavBarIcon(icon: Icons.home_rounded, index: 0, currentIndex: currentIndex, path: '/home'),
                      _NavBarIcon(icon: Icons.calendar_month_rounded, index: 1, currentIndex: currentIndex, path: '/upcoming'), // Upcoming (Curriculum)
                      _NavBarIcon(icon: Icons.folder_open_rounded, index: 2, currentIndex: currentIndex, path: '/archive'), // Archive (My Files)
                      _NavBarIcon(icon: Icons.play_circle_outline_rounded, index: 3, currentIndex: currentIndex, path: '/stream'),
                      _NavBarIcon(icon: Icons.person_outline_rounded, index: 4, currentIndex: currentIndex, path: '/profile'),
                    ],
                  ),
                ),
              ),
            ).animate().slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
          ),
        ],
      ),
    );
  }
}

class _NavBarIcon extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final String path;

  const _NavBarIcon({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final color = isSelected ? Colors.cyanAccent : Colors.grey;

    return GestureDetector(
      onTap: () => context.go(path),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26)
                .animate(target: isSelected ? 1 : 0)
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms),

            const SizedBox(height: 4),

            // 선택 표시 점 (Indicator)
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.cyanAccent : Colors.transparent,
              ),
            ).animate(target: isSelected ? 1 : 0).scale(),
          ],
        ),
      ),
    );
  }
}