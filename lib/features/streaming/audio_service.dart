import 'package:flutter/foundation.dart'; // debugPrint용
import 'package:just_audio/just_audio.dart';

class KraftAudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playUrl(String url) async {
    try {
      await _player.setUrl(url);
      _player.play();
    } catch (e) {
      debugPrint("Audio Error: $e"); // [수정] debugPrint 사용
    }
  }

  static Future<void> stop() async {
    await _player.stop();
  }
}