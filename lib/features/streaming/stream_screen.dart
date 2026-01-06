import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'audio_service.dart';
import 'player_provider.dart';

class StreamScreen extends ConsumerWidget {
  final MediaItem song;

  const StreamScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 배경 이미지 (블러 처리)
          Positioned.fill(
            child: song.artUri != null
                ? Image.network(song.artUri.toString(), fit: BoxFit.cover)
                : Container(color: const Color(0xFF111111)),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withOpacity(0.7)),
            ),
          ),

          // 플레이어 UI
          SafeArea(
            child: Column(
              children: [
                // 상단 닫기 버튼
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 40),
                    onPressed: () {
                      ref.read(isPlayerExpandedProvider.notifier).state = false;
                    },
                  ),
                ),

                const Spacer(),

                // 앨범 커버
                Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [const BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 10))],
                    image: song.artUri != null
                        ? DecorationImage(image: NetworkImage(song.artUri.toString()), fit: BoxFit.cover)
                        : null,
                    color: Colors.grey[900],
                  ),
                  child: song.artUri == null
                      ? const Icon(Icons.music_note, size: 100, color: Colors.white24)
                      : null,
                ),

                const SizedBox(height: 40),

                // 곡 정보
                Text(song.title,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center
                ),
                const SizedBox(height: 8),
                Text(song.artist ?? "Unknown Artist",
                    style: const TextStyle(color: Colors.white60, fontSize: 18)
                ),

                const SizedBox(height: 40),

                // 재생 컨트롤
                StreamBuilder<PlayerState>(
                  stream: KraftAudioService.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing ?? false;

                    if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                      return const SizedBox(
                        width: 80, height: 80,
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    return IconButton(
                      iconSize: 80,
                      icon: Icon(
                        playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: Colors.white,
                      ),
                      onPressed: playing ? KraftAudioService.pause : KraftAudioService.resume,
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 진행 바 (Slider)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StreamBuilder<Duration?>(
                    stream: KraftAudioService.durationStream,
                    builder: (context, snapshot) {
                      final duration = snapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration>(
                        stream: KraftAudioService.positionStream,
                        builder: (context, snapshot) {
                          var position = snapshot.data ?? Duration.zero;
                          if (position > duration) position = duration;

                          return Column(
                            children: [
                              Slider(
                                activeColor: Colors.white,
                                inactiveColor: Colors.white24,
                                min: 0.0,
                                max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                                value: position.inMilliseconds.toDouble(),
                                onChanged: (value) {
                                  KraftAudioService.seek(Duration(milliseconds: value.toInt()));
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(position), style: const TextStyle(color: Colors.white54)),
                                    Text(_formatDuration(duration), style: const TextStyle(color: Colors.white54)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}