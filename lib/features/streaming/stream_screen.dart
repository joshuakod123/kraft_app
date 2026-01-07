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
          // 1. 배경 (앨범 아트 블러)
          Positioned.fill(
            child: song.artUri != null
                ? Image.network(song.artUri.toString(), fit: BoxFit.cover)
                : Container(color: const Color(0xFF1a1a1a)),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),

          // 2. 메인 컨텐츠 (Overflow 방지)
          SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) {
                  // 화면이 너무 작을 경우를 대비한 스크롤 뷰
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 간격을 균등하게 배분
                          children: [
                            // [상단바] 닫기 버튼
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 36),
                                  onPressed: () {
                                    ref.read(isPlayerExpandedProvider.notifier).state = false;
                                  },
                                ),
                                const Spacer(),
                                const Text(
                                    "Now Playing",
                                    style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w600)
                                ),
                                const Spacer(),
                                // 균형을 위한 투명 아이콘 (더보기 버튼 위치)
                                IconButton(
                                  icon: const Icon(Icons.more_horiz, color: Colors.transparent),
                                  onPressed: null,
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // [앨범 아트] 화면 크기에 따라 유연하게 조절 (핵심 수정)
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: constraints.maxHeight * 0.45, // 전체 높이의 45%를 넘지 않음
                                maxWidth: constraints.maxWidth * 0.9,   // 전체 너비의 90%
                              ),
                              child: AspectRatio(
                                aspectRatio: 1, // 정사각형 비율 유지
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 30,
                                          offset: const Offset(0, 15)
                                      )
                                    ],
                                    image: song.artUri != null
                                        ? DecorationImage(image: NetworkImage(song.artUri.toString()), fit: BoxFit.cover)
                                        : null,
                                    color: Colors.grey[900],
                                  ),
                                  child: song.artUri == null
                                      ? const Icon(Icons.music_note_rounded, size: 80, color: Colors.white24)
                                      : null,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // [곡 제목 및 아티스트]
                            Column(
                              children: [
                                Text(
                                  song.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  song.artist ?? "Unknown Artist",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 16
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // [진행 바 Slider]
                            StreamBuilder<Duration?>(
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
                                        SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 4,
                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                            activeTrackColor: Colors.white,
                                            inactiveTrackColor: Colors.white24,
                                            thumbColor: Colors.white,
                                          ),
                                          child: Slider(
                                            min: 0.0,
                                            max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                                            value: position.inMilliseconds.toDouble(),
                                            onChanged: (value) {
                                              KraftAudioService.seek(Duration(milliseconds: value.toInt()));
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(_formatDuration(position), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                              Text(_formatDuration(duration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            // [재생 컨트롤]
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
                                  onPressed: () {},
                                ),
                                const SizedBox(width: 24),
                                StreamBuilder<PlayerState>(
                                  stream: KraftAudioService.playerStateStream,
                                  builder: (context, snapshot) {
                                    final playerState = snapshot.data;
                                    final processingState = playerState?.processingState;
                                    final playing = playerState?.playing ?? false;

                                    if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                                      return const SizedBox(
                                        width: 70, height: 70,
                                        child: Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                        ),
                                      );
                                    }

                                    return GestureDetector(
                                      onTap: playing ? KraftAudioService.pause : KraftAudioService.resume,
                                      child: Container(
                                        width: 70, height: 70,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 20)]
                                        ),
                                        child: Icon(
                                          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.black,
                                          size: 38,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 24),
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 40),
                                  onPressed: () {},
                                ),
                              ],
                            ),

                            // 하단 여백 확보
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  );
                }
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}