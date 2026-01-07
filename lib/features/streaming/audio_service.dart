import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/foundation.dart';

class KraftAudioService {
  static final AudioPlayer _player = AudioPlayer();

  // 스트림 게터
  static Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  static Stream<Duration?> get durationStream => _player.durationStream;
  static Stream<Duration> get positionStream => _player.positionStream;
  static AudioPlayer get instance => _player;

  // 초기화 (필요 시 호출)
  static Future<void> init() async {}

  // 음악 재생
  static Future<void> playMediaItem(MediaItem item) async {
    try {
      final url = item.extras?['url'] as String?;
      if (url == null || url.isEmpty) return;

      // 이미 같은 곡이면 재생만 재개
      if (_player.audioSource is UriAudioSource) {
        final currentUrl = (_player.audioSource as UriAudioSource).uri.toString();
        if (currentUrl == url) {
          if (!_player.playing) _player.play();
          return;
        }
      }

      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(url), tag: item),
      );
      await _player.play();

    } catch (e) {
      debugPrint("❌ [AudioService] 재생 오류: $e");
    }
  }

  static Future<void> pause() async => await _player.pause();
  static Future<void> resume() async => await _player.play();
  static Future<void> seek(Duration position) async => await _player.seek(position);

  // [중요] 정지 시 위치를 0으로 돌리고 멈춤
  static Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }
}