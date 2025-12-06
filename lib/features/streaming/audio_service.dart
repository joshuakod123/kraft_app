import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// [중요] 다른 파일에서 쓸 Song 모델
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

// 오디오 플레이어 (싱글톤)
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() => player.dispose());
  return player;
});

// 현재 재생 중인 노래 상태
final currentSongProvider = StateProvider<Song?>((ref) => null);

// 상태 스트림들
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

// 오디오 서비스 클래스
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