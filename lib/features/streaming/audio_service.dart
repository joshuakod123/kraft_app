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
  static Future<void> init() async {
    // 필요한 초기화 설정이 있다면 여기에
  }

  // 음악 재생 핵심 함수
  static Future<void> playMediaItem(MediaItem item) async {
    try {
      final url = item.extras?['url'] as String?;

      if (url == null || url.isEmpty) {
        debugPrint("❌ [AudioService] 재생 URL이 없습니다.");
        return;
      }

      debugPrint("▶️ [AudioService] 재생 시도: $url");

      // 이미 같은 곡이 재생 중이면 중단하지 않음
      if (_player.audioSource is UriAudioSource) {
        final currentUrl = (_player.audioSource as UriAudioSource).uri.toString();
        if (currentUrl == url) {
          if (!_player.playing) _player.play();
          return;
        }
      }

      // 오디오 소스 설정
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: item, // 알림창에 표시될 메타데이터
        ),
      );

      await _player.play();

    } catch (e) {
      debugPrint("❌ [AudioService] 재생 오류 발생: $e");
    }
  }

  static Future<void> pause() async => await _player.pause();
  static Future<void> resume() async => await _player.play();
  static Future<void> seek(Duration position) async => await _player.seek(position);
  static Future<void> stop() async => await _player.stop();
}