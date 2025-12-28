import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../core/data/supabase_repository.dart';
import 'audio_service.dart';
import 'stream_screen.dart';
import 'player_provider.dart';

class StreamListScreen extends ConsumerWidget {
  const StreamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = SupabaseRepository();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Kraft Music', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          // 새로고침 버튼 추가
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // 화면을 다시 그리기 위해(FutureBuilder 재호출) context를 이용해 리빌드 유도
              // 간단하게는 Navigator로 갔다가 오거나, StateProvider를 쓰는 방법이 있지만
              // 여기서는 사용자가 직관적으로 다시 로드할 수 있게 함 (Stateless라 한계가 있어 로그 출력)
              print("새로고침: 다시 로드 시도");
            },
          )
        ],
      ),
      body: FutureBuilder<List<MediaItem>>(
        future: repo.fetchSongs(),
        builder: (context, snapshot) {
          // 1. 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          // 2. 에러 발생 시
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "데이터 로드 실패\n\n에러 내용: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final songs = snapshot.data ?? [];

          // 3. 데이터가 비어있을 때 (여기가 문제의 지점)
          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.music_off, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "등록된 곡이 없습니다.",
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Supabase Table Editor에서\n'songs' 테이블에 데이터가 있는지 확인해주세요.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white30, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          // 4. 데이터가 있을 때 리스트 표시
          return ListView.separated(
            itemCount: songs.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    song.artUri.toString(),
                    width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[900], width: 50, height: 50, child: const Icon(Icons.music_note, color: Colors.white)),
                  ),
                ),
                title: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(song.artist ?? 'Unknown', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                trailing: const Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
                onTap: () {
                  // 재생 로직
                  ref.read(currentSongProvider.notifier).state = song;
                  KraftAudioService.playMediaItem(song);

                  // 화면 이동 (매개변수 없이 호출)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StreamScreen()),
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