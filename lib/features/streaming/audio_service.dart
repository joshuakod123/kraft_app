import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// [중요] Song 클래스 정의
class Song {
  final int id;
  final String title;
  final String artist;
  final String? coverUrl;
  final String audioUrl;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.coverUrl,
    required this.audioUrl,
  });
}

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

final currentSongProvider = StateProvider<Song?>((ref) => null);

final playerStateProvider = StreamProvider<PlayerState>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.playerStateStream;
});

final positionProvider = StreamProvider<Duration>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.positionStream;
});

final durationProvider = StreamProvider<Duration?>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.durationStream;
});

final audioServiceProvider = Provider((ref) => AudioService(ref));

class AudioService {
  final Ref _ref;
  AudioService(this._ref);

  AudioPlayer get _player => _ref.read(audioPlayerProvider);

  Future<void> playSong(Song song) async {
    _ref.read(currentSongProvider.notifier).state = song;
    try {
      await _player.setUrl(song.audioUrl);
      _player.play();
    } catch (e) {
      print("Audio Error: $e");
    }
  }

  void play() => _player.play();
  void pause() => _player.pause();
  void seek(Duration position) => _player.seek(position);
  void playNext() {}
  void playPrevious() {}
}