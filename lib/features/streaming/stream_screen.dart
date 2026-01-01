import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_service.dart';
import 'player_provider.dart';
import '../../core/data/supabase_repository.dart';

// 댓글 Provider (에러 방지용)
final commentsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, songId) {
  return SupabaseRepository().fetchComments(int.tryParse(songId) ?? 0);
});

class StreamScreen extends ConsumerWidget {
  // [수정] 매개변수 삭제! const StreamScreen({super.key});
  const StreamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // [중요] 전역 상태에서 곡 정보 가져오기
    final song = ref.watch(currentSongProvider);

    if (song == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("재생 중인 곡이 없습니다.", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: song.artUri != null
                ? Image.network(song.artUri.toString(), fit: BoxFit.cover)
                : Container(color: const Color(0xFF111111)),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 36),
                    onPressed: () => ref.read(isPlayerExpandedProvider.notifier).state = false,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20)],
                    image: song.artUri != null
                        ? DecorationImage(image: NetworkImage(song.artUri.toString()), fit: BoxFit.cover)
                        : null,
                    color: Colors.grey[900],
                  ),
                ),
                const Spacer(),
                Text(song.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                Text(song.artist ?? "Unknown", style: const TextStyle(color: Colors.white70, fontSize: 18)),
                const SizedBox(height: 30),
                _buildControls(),
                const SizedBox(height: 20),
                _buildProgressBar(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return StreamBuilder<PlayerState>(
      stream: KraftAudioService.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return IconButton(
          iconSize: 80,
          icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white),
          onPressed: playing ? KraftAudioService.pause : KraftAudioService.resume,
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration?>(
      stream: KraftAudioService.durationStream,
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: KraftAudioService.positionStream,
          builder: (context, snapshot) {
            var position = snapshot.data ?? Duration.zero;
            if (position > duration) position = duration;
            return Slider(
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
              value: position.inMilliseconds.toDouble(),
              max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
              onChanged: (v) => KraftAudioService.seek(Duration(milliseconds: v.toInt())),
            );
          },
        );
      },
    );
  }
}