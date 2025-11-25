import 'package:just_audio/just_audio.dart';

class KraftAudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playUrl(String url) async {
    try {
      await _player.setUrl(url);
      _player.play();
    } catch (e) {
      print("Audio Error: $e");
    }
  }

  static Future<void> stop() async {
    await _player.stop();
  }
}