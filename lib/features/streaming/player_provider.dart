import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

// 현재 재생 중인 곡 상태 관리
class CurrentSongNotifier extends StateNotifier<MediaItem?> {
  CurrentSongNotifier() : super(null);
  void setSong(MediaItem song) => state = song;
  void clear() => state = null;
}

final currentSongProvider = StateNotifierProvider<CurrentSongNotifier, MediaItem?>((ref) {
  return CurrentSongNotifier();
});

// [핵심 상태] 플레이어가 전체 화면인지(true), 미니 모드인지(false)
final isPlayerExpandedProvider = StateProvider<bool>((ref) => false);