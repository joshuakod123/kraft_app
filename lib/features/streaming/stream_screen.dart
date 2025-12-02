import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/state/global_providers.dart';
import '../../core/data/supabase_repository.dart';
import 'audio_service.dart'; // [필수]

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
            Container(width: 250, height: 250, color: Colors.grey.withOpacity(0.3), child: const Icon(Icons.music_note, size: 100, color: Colors.white)),
            const SizedBox(height: 30),
            Text(currentSong?.title ?? "Select a Song", style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(currentSong?.artist ?? "Artist", style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 30),

            Slider(
              activeColor: themeColor,
              min: 0,
              max: duration.inSeconds.toDouble(),
              value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
              onChanged: (v) => audioService.seek(Duration(seconds: v.toInt())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 좋아요 버튼
                IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.white, size: 30),
                    onPressed: () => SupabaseRepository().toggleSongLike(songId)
                ),
                const SizedBox(width: 40),
                // 재생 버튼
                FloatingActionButton(
                  backgroundColor: themeColor,
                  onPressed: () => isPlaying ? audioService.pause() : audioService.play(),
                  child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black),
                ),
                const SizedBox(width: 40),
                // (대칭을 위한 빈 아이콘)
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