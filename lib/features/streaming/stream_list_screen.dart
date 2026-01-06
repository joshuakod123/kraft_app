import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../core/data/supabase_repository.dart';
import 'stream_screen.dart';
import 'audio_service.dart';
import 'player_provider.dart';

class StreamListScreen extends ConsumerStatefulWidget {
  const StreamListScreen({super.key});

  @override
  ConsumerState<StreamListScreen> createState() => _StreamListScreenState();
}

class _StreamListScreenState extends ConsumerState<StreamListScreen> {
  // Repository 인스턴스
  final _repo = SupabaseRepository();
  late Future<List<MediaItem>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  void _loadSongs() {
    setState(() {
      _songsFuture = _repo.fetchSongs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = ref.watch(isPlayerExpandedProvider);
    final currentSong = ref.watch(currentSongProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Kraft Music',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSongs,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 노래 리스트
          FutureBuilder<List<MediaItem>>(
            future: _songsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text("에러 발생: ${snapshot.error}",
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(onPressed: _loadSongs, child: const Text("재시도"))
                    ],
                  ),
                );
              }

              final songs = snapshot.data ?? [];

              if (songs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_off, size: 64, color: Colors.white38),
                      const SizedBox(height: 16),
                      const Text("등록된 곡이 없습니다.", style: TextStyle(color: Colors.white60)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadSongs,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
                        child: const Text("목록 새로고침", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 100), // 플레이어 공간 확보
                itemCount: songs.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final isPlaying = currentSong?.id == song.id;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[800],
                        image: song.artUri != null
                            ? DecorationImage(image: NetworkImage(song.artUri.toString()), fit: BoxFit.cover)
                            : null,
                      ),
                      child: song.artUri == null
                          ? const Icon(Icons.music_note, color: Colors.white54)
                          : null,
                    ),
                    title: Text(song.title,
                        style: TextStyle(
                            color: isPlaying ? Colors.greenAccent : Colors.white,
                            fontWeight: FontWeight.bold
                        )
                    ),
                    subtitle: Text(song.artist ?? 'Unknown Artist',
                        style: const TextStyle(color: Colors.white60, fontSize: 12)
                    ),
                    trailing: Icon(
                      Icons.play_circle_fill,
                      color: isPlaying ? Colors.greenAccent : Colors.white24,
                      size: 32,
                    ),
                    onTap: () {
                      // 노래 재생 시작
                      ref.read(currentSongProvider.notifier).state = song;
                      ref.read(isPlayerExpandedProvider.notifier).state = true;
                      KraftAudioService.playMediaItem(song);
                    },
                  );
                },
              );
            },
          ),

          // 2. 전체 화면 플레이어 (조건부 렌더링)
          if (isExpanded && currentSong != null)
            Positioned.fill(
              child: StreamScreen(song: currentSong),
            ),
        ],
      ),
    );
  }
}