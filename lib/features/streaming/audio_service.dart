import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

// 전역에서 접근 가능한 오디오 서비스 (Riverpod Provider로 감싸도 좋습니다)
class KraftAudioService {
  // 외부에서 직접 제어하지 못하도록 private으로 선언하되, 필요한 스트림은 getter로 노출
  static final AudioPlayer _player = AudioPlayer();

  // --- Getters for UI ---
  static AudioPlayer get player => _player;
  static Stream<Duration> get positionStream => _player.positionStream;
  static Stream<Duration?> get durationStream => _player.durationStream;
  static Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // 현재 재생 중인 아이템의 ID (좋아요 기능 등에서 사용)
  static String? get currentId => _player.sequenceState?.currentSource?.tag?.id;

  // --- Actions ---
  static Future<void> playUrl(String url, {dynamic tag}) async {
    try {
      // AudioSource에 tag(MediaItem 등)를 함께 넣어주면 메타데이터 활용 가능
      final source = AudioSource.uri(Uri.parse(url), tag: tag);
      await _player.setAudioSource(source);
      _player.play();
    } catch (e) {
      debugPrint("Audio Play Error: $e");
    }
  }

  static Future<void> pause() async {
    await _player.pause();
  }

  static Future<void> resume() async {
    await _player.play();
  }

  static Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  static Future<void> stop() async {
    await _player.stop();
  }
}