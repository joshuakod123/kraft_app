import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/department_enum.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';
import '../../features/auth/auth_provider.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRedirectIfNeeded();
    });
  }

  Future<void> _checkAndRedirectIfNeeded() async {
    final authStatus = ref.read(authProvider);
    if (authStatus != AuthStatus.authenticated) return;
    final profile = await SupabaseRepository().getUserProfile();
    if (profile != null && profile['is_temp_password'] == true) {
      if (!mounted) return;
      final location = GoRouterState.of(context).uri.toString();
      if (!location.startsWith('/profile')) {
        context.go('/profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next == AuthStatus.authenticated) {
        _checkAndRedirectIfNeeded();
      }
    });

    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getIndex(location);
    final currentSong = ref.watch(currentSongProvider);
    final isExpanded = ref.watch(isPlayerExpandedProvider);

    const double navBarHeight = 80.0;
    const double miniPlayerHeight = 68.0;

    return PopScope(
      canPop: !isExpanded,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (isExpanded) {
          ref.read(isPlayerExpandedProvider.notifier).state = false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              bottom: navBarHeight,
              child: widget.child,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: navBarHeight,
              child: _buildGlassNavBar(context, currentIndex),
            ),
            // [수정] currentSong이 있을 때만 플레이어 표시
            if (currentSong != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                // 확장되면 전체화면, 아니면 하단 바 위
                top: isExpanded ? 0 : null,
                bottom: isExpanded ? 0 : navBarHeight,
                left: 0,
                right: 0,
                height: isExpanded ? null : miniPlayerHeight,
                child: GestureDetector(
                  onTap: () {
                    if (!isExpanded) {
                      ref.read(isPlayerExpandedProvider.notifier).state = true;
                    }
                  },
                  onVerticalDragEnd: (details) {
                    if (isExpanded && details.primaryVelocity! > 500) {
                      ref.read(isPlayerExpandedProvider.notifier).state = false;
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isExpanded
                        ? const StreamScreen() // [핵심 수정] 인자값 없이 호출
                        : const MiniPlayer(),   // [핵심 수정] 인자값 없이 호출
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
      color: Colors.black, // Glass 효과 대신 완전 불투명 블랙으로 변경 (가독성 위해)
      padding: const EdgeInsets.only(top: 10),
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
          // Stream 탭을 눌렀을 때
          final currentSong = ref.read(currentSongProvider);
          if (currentSong != null) {
            // 재생 중인 곡이 있으면 플레이어 확장
            ref.read(isPlayerExpandedProvider.notifier).state = true;
          } else {
            // 없으면 그냥 화면 이동
            context.go(path);
          }
          return;
        }
        context.go(path);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? dept.color : Colors.grey, size: 28)
                .animate(target: isSelected ? 1 : 0)
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms),
          ],
        ),
      ),
    );
  }
}