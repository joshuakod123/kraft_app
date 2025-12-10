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
  final Widget child; // GoRouter가 전달해주는 현재 화면
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getIndex(location);
    final currentSong = ref.watch(currentSongProvider);
    final isExpanded = ref.watch(isPlayerExpandedProvider);

    // 수치 상수
    const double navBarHeight = 80.0;
    const double miniPlayerHeight = 68.0;
    const double miniPlayerMargin = 12.0;

    return PopScope(
      // 플레이어가 확장된 상태라면 앱 종료를 막고 플레이어를 닫음
      canPop: !isExpanded,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (isExpanded) {
          ref.read(isPlayerExpandedProvider.notifier).state = false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // [중요] 키보드가 올라와도 배경화면이 찌그러지지 않도록 false 설정
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 1. 메인 앱 화면 (탭에 따라 바뀌는 부분)
            Positioned.fill(
              bottom: navBarHeight, // 네비게이션 바 공간 확보
              child: widget.child,
            ),

            // 2. 하단 네비게이션 바
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: navBarHeight,
              child: _buildGlassNavBar(context, currentIndex),
            ),

            // 3. 뮤직 플레이어 오버레이 (핵심)
            // 페이지 이동이 아니라, 위치와 크기만 애니메이션으로 변경
            if (currentSong != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.fastOutSlowIn,
                // 확장되면 화면 전체(0,0,0,0), 아니면 미니 플레이어 위치
                top: isExpanded ? 0 : MediaQuery.of(context).size.height - navBarHeight - miniPlayerHeight - miniPlayerMargin,
                bottom: isExpanded ? 0 : navBarHeight + miniPlayerMargin,
                left: isExpanded ? 0 : miniPlayerMargin,
                right: isExpanded ? 0 : miniPlayerMargin,
                child: GestureDetector(
                  // 탭하면 확장
                  onTap: () {
                    if (!isExpanded) {
                      ref.read(isPlayerExpandedProvider.notifier).state = true;
                    }
                  },
                  // 드래그 제스처로 닫기/열기
                  onVerticalDragEnd: (details) {
                    if (isExpanded && details.primaryVelocity! > 500) {
                      // 아래로 빠르게 스와이프 -> 닫기
                      ref.read(isPlayerExpandedProvider.notifier).state = false;
                    } else if (!isExpanded && details.primaryVelocity! < -500) {
                      // 위로 빠르게 스와이프 -> 열기
                      ref.read(isPlayerExpandedProvider.notifier).state = true;
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      // 미니일 때는 둥글게, 전체화면일 때는 직각
                      borderRadius: isExpanded ? BorderRadius.zero : BorderRadius.circular(12),
                      boxShadow: [
                        if (!isExpanded)
                          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      // 상태에 따라 다른 위젯 보여주기
                      child: isExpanded
                          ? StreamScreen(mediaItem: currentSong) // 전체 화면 플레이어
                          : MiniPlayer(song: currentSong),       // 미니 플레이어
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
          // 재생 버튼 탭 시 동작: 페이지 이동 X -> 플레이어 확장 O
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
        // 3번(Stream) 탭을 눌렀을 때
        if (index == 3) {
          final currentSong = ref.read(currentSongProvider);
          if (currentSong != null) {
            // 이미 재생 중인 곡이 있으면 확장만 함
            ref.read(isPlayerExpandedProvider.notifier).state = true;
          } else {
            // 재생 중인 곡이 없으면 페이지 이동 (혹은 아무 동작 안함)
            context.go(path);
          }
          return;
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