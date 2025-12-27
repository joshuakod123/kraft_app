import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart'; // [중요] 이거 없으면 MediaItem 에러 납니다!
import '../../core/data/supabase_repository.dart';
import 'stream_screen.dart';
import 'audio_service.dart';

class StreamListScreen extends ConsumerWidget {
  const StreamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = SupabaseRepository();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Kraft Music',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<MediaItem>>( // [Fix] 리턴 타입을 명확히 명시
        future: repo.fetchSongs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError) {
            return Center(child: Text("데이터 로드 실패: ${snapshot.error}",
                style: const TextStyle(color: Colors.red)));
          }

          final songs = snapshot.data ?? [];

          if (songs.isEmpty) {
            return const Center(child: Text("등록된 곡이 없습니다.",
                style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            itemCount: songs.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    song.artUri.toString(),
                    width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[900], width: 50, height: 50,
                            child: const Icon(Icons.music_note, color: Colors.white)),
                  ),
                ),
                title: Text(song.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(song.artist ?? 'Unknown',
                    style: const TextStyle(color: Colors.white60, fontSize: 13)),
                trailing: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                onTap: () {
                  // 1. 오디오 서비스를 통해 즉시 재생
                  KraftAudioService.playMediaItem(song);

                  // 2. 상세 플레이어 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StreamScreen(mediaItem: song),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}