import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class KraftAudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  static Stream<Duration?> get durationStream => _player.durationStream;
  static Stream<Duration> get positionStream => _player.positionStream;

  static Future<void> playMediaItem(MediaItem item) async {
    try {
      final url = item.extras?['url'] ?? '';
      if (url.isEmpty) {
        print("재생 URL이 없습니다.");
        return;
      }

      // 기존 소스와 같으면 재생만 수행 (끊김 방지)
      if (_player.audioSource != null && _player.audioSource is UriAudioSource) {
        final currentUri = (_player.audioSource as UriAudioSource).uri;
        if (currentUri.toString() == url) {
          if (!_player.playing) _player.play();
          return;
        }
      }

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: item,
        ),
      );
      _player.play();
    } catch (e) {
      print("재생 중 오류 발생: $e");
    }
  }

  static Future<void> pause() => _player.pause();
  static Future<void> resume() => _player.play();
  static Future<void> seek(Duration position) => _player.seek(position);
}