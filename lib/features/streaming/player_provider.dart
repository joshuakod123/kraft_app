import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

// 현재 재생 중인 곡 (재생 중이 아니면 null)
class CurrentSongNotifier extends StateNotifier<MediaItem?> {
  CurrentSongNotifier() : super(null);
  void setSong(MediaItem song) => state = song;
  void clear() => state = null;
}

final currentSongProvider = StateNotifierProvider<CurrentSongNotifier, MediaItem?>((ref) {
  return CurrentSongNotifier();
});

// [핵심] 플레이어가 전체 화면으로 확장되었는지 여부 (true: 전체화면, false: 미니플레이어)
final isPlayerExpandedProvider = StateProvider<bool>((ref) => false);