import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/global_providers.dart';
import '../../features/streaming/mini_player.dart';
import '../../features/streaming/player_provider.dart'; // [1] 위에서 만든 Provider 임포트

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 현재 탭 위치 파악
    final String location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/upcoming')) currentIndex = 1;
    else if (location.startsWith('/team_members')) currentIndex = 2;
    else if (location.startsWith('/stream')) currentIndex = 3;
    else if (location.startsWith('/profile')) currentIndex = 4;

    // 2. [핵심] 현재 재생 중인 곡 가져오기
    final currentSong = ref.watch(currentSongProvider);

    // 3. 미니 플레이어 표시 여부 결정
    // 노래가 있고(null 아님) && 현재 탭이 스트리밍 탭(3)이 아닐 때만 표시
    final bool showMiniPlayer = currentSong != null && currentIndex != 3;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          // 탭 화면
          child,

          // [핵심 기능 구현] 미니 플레이어 (조건부 렌더링)
          if (showMiniPlayer)
            Positioned(
              bottom: 110, // 네비게이션 바 위
              left: 20,
              right: 20,
              child: MiniPlayer(song: currentSong) // 데이터 전달
                  .animate()
                  .slideY(begin: 1, end: 0, curve: Curves.easeOutBack, duration: 400.ms)
                  .fadeIn(),
            ),

          // 하단 네비게이션 바
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildGlassNavBar(context, currentIndex, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassNavBar(BuildContext context, int currentIndex, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarIcon(icon: Icons.home_rounded, index: 0, currentIndex: currentIndex, path: '/home'),
              _NavBarIcon(icon: Icons.calendar_month_rounded, index: 1, currentIndex: currentIndex, path: '/upcoming'),
              _NavBarIcon(icon: Icons.groups_3_rounded, index: 2, currentIndex: currentIndex, path: '/team_members'),
              _NavBarIcon(icon: Icons.play_circle_outline_rounded, index: 3, currentIndex: currentIndex, path: '/stream'),
              _NavBarIcon(icon: Icons.person_outline_rounded, index: 4, currentIndex: currentIndex, path: '/profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarIcon extends ConsumerWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final String path;

  const _NavBarIcon({super.key, required this.icon, required this.index, required this.currentIndex, required this.path});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dept = ref.watch(currentDeptProvider);
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => context.go(path),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: isSelected ? dept.color : Colors.grey, size: 26)
            .animate(target: isSelected ? 1 : 0)
            .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms),
      ),
    );
  }
}