// lib/features/streaming/audio_service.dart
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
      if (url.isEmpty) return;

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: item,
        ),
      );
      _player.play();
    } catch (e) {
      print("재생 에러: $e");
    }
  }

  static Future<void> pause() => _player.pause();
  static Future<void> resume() => _player.play();
  static Future<void> seek(Duration position) => _player.seek(position);
}