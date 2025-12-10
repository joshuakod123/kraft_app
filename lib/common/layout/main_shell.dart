import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../features/streaming/mini_player.dart';
import '../../features/streaming/player_provider.dart';
import '../../features/streaming/stream_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = _getIndex(location);

    final currentSong = ref.watch(currentSongProvider);
    final isExpanded = ref.watch(isPlayerExpandedProvider);

    // 하단 네비게이션 바 높이
    const double navBarHeight = 80.0;
    // 미니 플레이어 높이
    const double miniPlayerHeight = 68.0;

    return PopScope(
      canPop: !isExpanded, // 플레이어가 열려있으면 앱 종료 방지하고 플레이어 닫기
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (isExpanded) {
          ref.read(isPlayerExpandedProvider.notifier).state = false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false, // [Pixel Overflow 방지 핵심] 키보드 올라와도 배경 고정
        body: Stack(
          children: [
            // [Layer 1] 탭 화면 (홈, 일정 등)
            Positioned.fill(
              bottom: navBarHeight,
              child: widget.child,
            ),

            // [Layer 2] 하단 네비게이션 바
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: navBarHeight,
              child: _buildGlassNavBar(context, currentIndex),
            ),

            // [Layer 3] 뮤직 플레이어 (Mini <-> Full 애니메이션)
            if (currentSong != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                // 확장되면 화면 전체 덮음 (top:0), 아니면 하단 바 위에 위치
                top: isExpanded ? 0 : MediaQuery.of(context).size.height - navBarHeight - miniPlayerHeight - 12,
                bottom: isExpanded ? 0 : navBarHeight + 12,
                left: isExpanded ? 0 : 12,
                right: isExpanded ? 0 : 12,
                child: GestureDetector(
                  onTap: () {
                    // 미니 플레이어 상태일 때 누르면 확장
                    if (!isExpanded) {
                      ref.read(isPlayerExpandedProvider.notifier).state = true;
                    }
                  },
                  onVerticalDragEnd: (details) {
                    // 제스처로 닫기/열기
                    if (isExpanded && details.primaryVelocity! > 500) {
                      ref.read(isPlayerExpandedProvider.notifier).state = false;
                    } else if (!isExpanded && details.primaryVelocity! < -500) {
                      ref.read(isPlayerExpandedProvider.notifier).state = true;
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: isExpanded ? BorderRadius.zero : BorderRadius.circular(12),
                      boxShadow: [
                        if (!isExpanded)
                          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isExpanded
                          ? StreamScreen(mediaItem: currentSong) // 전체 화면
                          : MiniPlayer(song: currentSong),       // 미니 모드
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _getIndex(String location) {
    if (location.startsWith('/upcoming')) return 1;
    if (location.startsWith('/team_members')) return 2;
    if (location.startsWith('/stream')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  Widget _buildGlassNavBar(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavBarIcon(icon: Icons.home_rounded, index: 0, currentIndex: currentIndex, path: '/home'),
          _NavBarIcon(icon: Icons.calendar_month_rounded, index: 1, currentIndex: currentIndex, path: '/upcoming'),
          _NavBarIcon(icon: Icons.groups_3_rounded, index: 2, currentIndex: currentIndex, path: '/team_members'),
          // 3번 탭(재생)을 누르면 페이지 이동 대신 플레이어 확장
          _NavBarIcon(icon: Icons.play_circle_outline_rounded, index: 3, currentIndex: currentIndex, path: '/stream'),
          _NavBarIcon(icon: Icons.person_outline_rounded, index: 4, currentIndex: currentIndex, path: '/profile'),
        ],
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
      onTap: () {
        if (index == 3) {
          final currentSong = ref.read(currentSongProvider);
          if (currentSong != null) {
            ref.read(isPlayerExpandedProvider.notifier).state = true;
            return;
          }
        }
        context.go(path);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Icon(icon, color: isSelected ? dept.color : Colors.grey, size: 28)
            .animate(target: isSelected ? 1 : 0)
            .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms),
      ),
    );
  }
}