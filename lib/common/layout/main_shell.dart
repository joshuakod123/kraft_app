import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/data/supabase_repository.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/streaming/audio_service.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndRedirectIfNeeded());
  }

  Future<void> _checkAndRedirectIfNeeded() async {
    final authStatus = ref.read(authProvider);
    if (authStatus != AuthStatus.authenticated) return;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, next) {
      if (next == AuthStatus.authenticated) _checkAndRedirectIfNeeded();
    });

    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getIndex(location);
    final currentSong = ref.watch(currentSongProvider);
    final isExpanded = ref.watch(isPlayerExpandedProvider);

    // 미니 플레이어가 있을 때 바닥 여백을 충분히 줍니다.
    final double contentBottomPadding = currentSong != null ? 180.0 : 100.0;

    return PopScope(
      canPop: !isExpanded,
      onPopInvoked: (didPop) {
        if (!didPop && isExpanded) {
          ref.read(isPlayerExpandedProvider.notifier).state = false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        body: Stack(
          children: [
            // 1. 메인 컨텐츠
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(bottom: contentBottomPadding),
                child: widget.child,
              ),
            ),

            // 2. 하단 네비게이션 바
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildGlassNavBar(currentIndex),
            ),

            // 3. 뮤직 플레이어
            if (currentSong != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: isExpanded ? 0 : null,
                // 탭바(85) + 여백(10) 정도 띄워서 배치
                bottom: isExpanded ? 0 : 95,
                left: 0,
                right: 0,
                // [수정] 높이를 64 -> 74로 늘려서 구겨짐 방지
                height: isExpanded ? null : 74,
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (!isExpanded && details.primaryVelocity! < -0) {
                      ref.read(isPlayerExpandedProvider.notifier).state = true;
                    } else if (isExpanded && details.primaryVelocity! > 0) {
                      ref.read(isPlayerExpandedProvider.notifier).state = false;
                    }
                  },
                  onTap: () {
                    if (!isExpanded) {
                      ref.read(isPlayerExpandedProvider.notifier).state = true;
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isExpanded
                        ? StreamScreen(song: currentSong)
                        : _MiniPlayer(song: currentSong),
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

  Widget _buildGlassNavBar(int currentIndex) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 85,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarIcon(
                  selectedIcon: Icons.home_rounded, unselectedIcon: Icons.home_outlined,
                  index: 0, currentIndex: currentIndex, path: '/home', label: '홈'
              ),
              _NavBarIcon(
                  selectedIcon: Icons.calendar_month_rounded, unselectedIcon: Icons.calendar_today_outlined,
                  index: 1, currentIndex: currentIndex, path: '/upcoming', label: '일정'
              ),
              _NavBarIcon(
                  selectedIcon: Icons.groups_rounded, unselectedIcon: Icons.groups_outlined,
                  index: 2, currentIndex: currentIndex, path: '/team_members', label: '멤버'
              ),
              _NavBarIcon(
                  selectedIcon: Icons.play_circle_fill, unselectedIcon: Icons.play_circle_outline,
                  index: 3, currentIndex: currentIndex, path: '/stream', label: '뮤직'
              ),
              _NavBarIcon(
                  selectedIcon: Icons.person_rounded, unselectedIcon: Icons.person_outline,
                  index: 4, currentIndex: currentIndex, path: '/profile', label: '내 정보'
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarIcon extends ConsumerWidget {
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;
  final int index;
  final int currentIndex;
  final String path;

  const _NavBarIcon({
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.path,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (index == 3) {
          if (ref.read(currentSongProvider) != null) {
            ref.read(isPlayerExpandedProvider.notifier).state = true;
          } else {
            context.go(path);
          }
          return;
        }
        context.go(path);
      },
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected ? Colors.white : Colors.white54,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// [수정됨] 찌그러짐 방지를 위해 ListTile 대신 Row 사용
class _MiniPlayer extends ConsumerWidget {
  final MediaItem song;
  const _MiniPlayer({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // 수직 마진 제거
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 내부 패딩으로 조절
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. 앨범 아트
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44, height: 44,
              child: song.artUri != null
                  ? Image.network(song.artUri.toString(), fit: BoxFit.cover)
                  : Container(color: Colors.grey[800], child: const Icon(Icons.music_note, color: Colors.white54)),
            ),
          ),

          const SizedBox(width: 12),

          // 2. 제목 & 가수 (공간 차지)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // 최소 높이만 사용
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist ?? 'Unknown Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // 3. 컨트롤 버튼
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<PlayerState>(
                stream: KraftAudioService.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return IconButton(
                    icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white),
                    iconSize: 32,
                    padding: EdgeInsets.zero, // 패딩 제거로 공간 확보
                    constraints: const BoxConstraints(), // 최소 크기 제약 해제
                    onPressed: playing ? KraftAudioService.pause : KraftAudioService.resume,
                  );
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  KraftAudioService.stop();
                  ref.read(currentSongProvider.notifier).state = null;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}