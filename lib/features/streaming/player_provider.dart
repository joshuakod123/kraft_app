// lib/features/streaming/player_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

// 현재 재생 중인 곡을 관리하는 상태
class CurrentSongNotifier extends StateNotifier<MediaItem?> {
  CurrentSongNotifier() : super(null); // 처음엔 아무것도 없음

  // 곡 재생 시작 (이 함수를 호출하면 미니 플레이어가 뜹니다)
  void setSong(MediaItem song) {
    state = song;
  }

  // 곡 끄기
  void clear() {
    state = null;
  }
}

// 전역 Provider 정의
final currentSongProvider = StateNotifierProvider<CurrentSongNotifier, MediaItem?>((ref) {
  return CurrentSongNotifier();
});