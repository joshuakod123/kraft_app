import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/state/global_providers.dart';
import '../../core/data/supabase_repository.dart';
import 'audio_service.dart';

class StreamScreen extends ConsumerWidget {
  const StreamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final audioService = ref.read(audioServiceProvider);
    final playerState = ref.watch(playerStateProvider);
    final isPlaying = playerState.value?.playing ?? false;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final themeColor = ref.watch(currentDeptProvider).color;
    final int songId = currentSong?.id ?? 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // 앨범 아트
            Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 20)],
              ),
              child: const Icon(Icons.music_note, size: 100, color: Colors.white),
            ),
            const SizedBox(height: 40),

            // 제목 & 아티스트
            Text(currentSong?.title ?? "Select a Song", style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(currentSong?.artist ?? "Artist", style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 40),

            // 진행 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Slider(
                activeColor: themeColor,
                inactiveColor: Colors.white12,
                min: 0,
                max: duration.inSeconds.toDouble(),
                value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                onChanged: (v) => audioService.seek(Duration(seconds: v.toInt())),
              ),
            ),

            // 컨트롤 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 좋아요 버튼 (Streaming의 유일한 인터랙션)
                StreamBuilder<Map<String, dynamic>>(
                  stream: SupabaseRepository().getSongLikeStatus(songId),
                  builder: (context, snapshot) {
                    final isLiked = snapshot.data?['isLiked'] ?? false;
                    return IconButton(
                      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : Colors.white, size: 30),
                      onPressed: () => SupabaseRepository().toggleSongLike(songId),
                    );
                  },
                ),
                // 재생/일시정지
                FloatingActionButton(
                  backgroundColor: themeColor,
                  onPressed: () => isPlaying ? audioService.pause() : audioService.play(),
                  child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 36),
                ),
                // (공간 맞춤용 빈 아이콘)
                const SizedBox(width: 48),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}