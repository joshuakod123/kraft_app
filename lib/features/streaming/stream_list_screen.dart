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
  late Future<List<MediaItem>> _songsFuture;
  final _repo = SupabaseRepository();

  @override
  void initState() {
    super.initState();
    _songsFuture = _repo.fetchSongs();
  }

  Future<void> _refresh() async {
    setState(() {
      _songsFuture = _repo.fetchSongs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Kraft Music', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<MediaItem>>(
        future: _songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(child: Text("에러: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final songs = snapshot.data ?? [];

          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.music_off_outlined, size: 60, color: Colors.white38),
                  SizedBox(height: 16),
                  Text("재생할 곡이 없습니다.", style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  Text(
                    "Supabase Table에 데이터를 추가했는지 확인해주세요.\n(SQL Insert 실행 필요)",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white30, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.artUri != null
                      ? Image.network(song.artUri.toString(), width: 50, height: 50, fit: BoxFit.cover)
                      : Container(color: Colors.grey[800], width: 50, height: 50, child: const Icon(Icons.music_note, color: Colors.white)),
                ),
                title: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(song.artist ?? 'Unknown', style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                onTap: () {
                  // [수정] setSong 대신 state에 직접 할당 (.notifier 사용 시)
                  // StateProvider로 바꿨으므로 아래 코드가 맞습니다.
                  ref.read(currentSongProvider.notifier).state = song;
                  ref.read(isPlayerExpandedProvider.notifier).state = true;

                  KraftAudioService.playMediaItem(song);
                },
              );
            },
          );
        },
      ),
    );
  }
}