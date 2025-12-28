// lib/features/streaming/stream_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'audio_service.dart';
import 'player_provider.dart';

class StreamScreen extends ConsumerWidget {
  const StreamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 전역 상태에서 현재 노래를 감시합니다.
    final song = ref.watch(currentSongProvider);

    if (song == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: Text("재생 중인 곡이 없습니다.", style: TextStyle(color: Colors.white)))
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: song.artUri != null
                ? Image.network(song.artUri.toString(), fit: BoxFit.cover)
                : Container(color: Colors.grey[900]),
          ),
          Positioned.fill(
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(color: Colors.black.withOpacity(0.6))
              )
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(ref),
                const Spacer(),
                _buildAlbumArt(song),
                const Spacer(),
                _buildSongInfo(song),
                const SizedBox(height: 30),
                _buildControls(),
                _buildProgressBar(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 36),
        onPressed: () => ref.read(isPlayerExpandedProvider.notifier).state = false,
      ),
    );
  }

  Widget _buildAlbumArt(MediaItem song) {
    return Container(
      width: 280, height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: song.artUri != null ? DecorationImage(image: NetworkImage(song.artUri.toString()), fit: BoxFit.cover) : null,
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
    );
  }

  Widget _buildSongInfo(MediaItem song) {
    return Column(
      children: [
        Text(song.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(song.artist ?? "Unknown", style: const TextStyle(color: Colors.white70, fontSize: 18)),
      ],
    );
  }

  Widget _buildControls() {
    return StreamBuilder(
      stream: KraftAudioService.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 70,
              icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white),
              onPressed: isPlaying ? KraftAudioService.pause : KraftAudioService.resume,
            ),
          ],
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