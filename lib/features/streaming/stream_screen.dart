import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/state/global_providers.dart';
import '../../core/data/supabase_repository.dart';
import 'audio_service.dart';

class StreamScreen extends ConsumerWidget {
  const StreamScreen({super.key});

  void _showComments(BuildContext context, int songId, Color themeColor) {
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(color: Color(0xFF121212), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("COMMENTS", style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: SupabaseRepository().getSongComments(songId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) return const Center(child: Text("No comments yet.", style: TextStyle(color: Colors.grey)));
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      final user = c['user'] ?? {};
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: themeColor.withOpacity(0.2), child: Text((user['name']?[0] ?? '?').toUpperCase(), style: TextStyle(color: themeColor))),
                        title: Text(user['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(c['content'], style: const TextStyle(color: Colors.white70)),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Add a comment...", hintStyle: const TextStyle(color: Colors.grey),
                        filled: true, fillColor: Colors.white10,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: themeColor),
                    onPressed: () async {
                      if (commentCtrl.text.isNotEmpty) {
                        await SupabaseRepository().addSongComment(songId, commentCtrl.text);
                        commentCtrl.clear();
                      }
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final audioService = ref.read(audioServiceProvider);
    final playerState = ref.watch(playerStateProvider);
    final isPlaying = playerState?.playing ?? false;
    final duration = ref.watch(durationProvider);
    final position = ref.watch(positionProvider);
    final dept = ref.watch(currentDeptProvider);
    final themeColor = dept.color;

    // 현재는 테스트용으로 Song ID를 1로 고정
    // 실제로는 Song 모델에 id가 있어야 함
    final int songId = 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0, -0.5), radius: 1.0, colors: [themeColor.withOpacity(0.2), Colors.black])),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    Text('NOW PLAYING', style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const Icon(Icons.more_horiz, color: Colors.white),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 300, height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: themeColor.withOpacity(0.4), blurRadius: 40)],
                      image: const DecorationImage(image: AssetImage('assets/images/logo.png'), fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // 곡 정보 및 좋아요 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currentSong?.title ?? 'Select Song', style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            Text(currentSong?.artist ?? 'Artist', style: const TextStyle(color: Colors.white54, fontSize: 16)),
                          ],
                        ),
                        // [기능] 좋아요 버튼
                        StreamBuilder<Map<String, dynamic>>(
                          stream: SupabaseRepository().getSongLikeStatus(songId),
                          builder: (context, snapshot) {
                            final isLiked = snapshot.data?['isLiked'] ?? false;
                            final count = snapshot.data?['count'] ?? 0;
                            return Column(
                              children: [
                                IconButton(
                                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : Colors.white),
                                  onPressed: () => SupabaseRepository().toggleSongLike(songId),
                                ),
                                Text("$count", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // 재생 바
                    Slider(
                      activeColor: themeColor, inactiveColor: Colors.white12,
                      min: 0.0, max: duration?.inMilliseconds.toDouble() ?? 1.0,
                      value: position?.inMilliseconds.toDouble().clamp(0.0, duration?.inMilliseconds.toDouble() ?? 1.0) ?? 0.0,
                      onChanged: (v) => audioService.seek(Duration(milliseconds: v.toInt())),
                    ),
                    const SizedBox(height: 20),

                    // 컨트롤러 및 댓글 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // [기능] 댓글 버튼
                        IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white), onPressed: () => _showComments(context, songId, themeColor)),
                        IconButton(onPressed: audioService.playPrevious, icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32)),
                        FloatingActionButton(backgroundColor: themeColor, child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black), onPressed: () => isPlaying ? audioService.pause() : audioService.play()),
                        IconButton(onPressed: audioService.playNext, icon: const Icon(Icons.skip_next, color: Colors.white, size: 32)),
                        const IconButton(icon: Icon(Icons.share, color: Colors.white), onPressed: null),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}