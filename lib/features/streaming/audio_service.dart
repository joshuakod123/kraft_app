import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:just_audio/just_audio.dart';

// [중요] Song 모델 정의 (다른 파일에서 이 클래스를 씁니다)
class Song {
  final int id;
  final String title;
  final String artist;
  final String? coverUrl;
  final String audioUrl; // 실제 mp3 파일 주소

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.coverUrl,
    required this.audioUrl,
  });
}

// 1. 오디오 플레이어 인스턴스 (앱 전역에서 하나만 사용)
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() {
    player.dispose();
  });
  return player;
});

// 2. 현재 재생 중인 노래 상태
final currentSongProvider = StateProvider<Song?>((ref) => null);

// 3. 플레이어 상태 스트림 (재생/일시정지/로딩 등)
final playerStateProvider = StreamProvider<PlayerState>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.playerStateStream;
});

// 4. 재생 위치 스트림
final positionProvider = StreamProvider<Duration>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.positionStream;
});

// 5. 곡 길이 스트림
final durationProvider = StreamProvider<Duration?>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.durationStream;
});

// [Service] 오디오 로직 담당
final audioServiceProvider = Provider((ref) => AudioService(ref));

class AudioService {
  final Ref _ref;
  AudioService(this._ref);

  AudioPlayer get _player => _ref.read(audioPlayerProvider);

  Future<void> playSong(Song song) async {
    // 현재 곡 정보 업데이트
    _ref.read(currentSongProvider.notifier).state = song;

    try {
      // 오디오 소스 설정 및 재생
      await _player.setUrl(song.audioUrl);
      _player.play();
    } catch (e) {
      // 에러 처리 (로그 출력 등)
      print("Error playing audio: $e");
    }
  }

  void play() => _player.play();
  void pause() => _player.pause();
  void seek(Duration position) => _player.seek(position);

  // 다음 곡/이전 곡 로직은 플레이리스트가 필요하므로 일단 비워둡니다.
  void playNext() {}
  void playPrevious() {}
}