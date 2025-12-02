import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// [모델] 이 Song 클래스가 'StreamScreen'에서 쓰입니다.
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

// 오디오 플레이어 Provider
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() => player.dispose());
  return player;
});

// [수정] 가장 간단하고 확실한 StateProvider 사용
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
    // StateProvider 값 업데이트
    _ref.read(currentSongProvider.notifier).state = song;

    try {
      await _player.setUrl(song.audioUrl);
      _player.play();
    } catch (e) {
      print("Audio Play Error: $e");
    }
  }

  void play() => _player.play();
  void pause() => _player.pause();
  void seek(Duration position) => _player.seek(position);
  void playNext() {}
  void playPrevious() {}
}