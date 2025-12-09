import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:glass_kit/glass_kit.dart'; // GlassCard 사용을 위해

import '../../core/data/supabase_repository.dart';
import '../../features/streaming/audio_service.dart';
import '../../theme/app_theme.dart';

// --- Providers ---

// 현재 곡의 댓글 목록을 가져오는 Provider
final commentsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, int>((ref, songId) {
  return SupabaseRepository().fetchComments(songId);
});

// 현재 곡의 좋아요 상태를 관리하는 Provider
final isLikedProvider = StateProvider.family.autoDispose<bool, int>((ref, songId) {
  return false; // 초기값 (나중에 로드됨)
});

class StreamScreen extends ConsumerStatefulWidget {
  final MediaItem mediaItem;

  // AudioService에서 넘겨받는 식이라면 생성자 조정 필요
  // 여기서는 단순히 화면 전환 시 데이터를 받는다고 가정
  const StreamScreen({super.key, required this.mediaItem});

  @override
  ConsumerState<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends ConsumerState<StreamScreen> {
  final TextEditingController _commentController = TextEditingController();
  final _repo = SupabaseRepository();
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  void _loadLikeStatus() async {
    final songId = int.parse(widget.mediaItem.id);
    final liked = await _repo.isSongLiked(songId);
    if (mounted) {
      setState(() {
        _isLiked = liked;
      });
    }
  }

  Future<void> _toggleLike() async {
    final songId = int.parse(widget.mediaItem.id);
    // UI 낙관적 업데이트 (즉시 반응)
    setState(() {
      _isLiked = !_isLiked;
    });
    // DB 업데이트
    await _repo.toggleSongLike(songId);
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final content = _commentController.text;
    final songId = int.parse(widget.mediaItem.id);

    _commentController.clear(); // 입력창 비우기
    FocusScope.of(context).unfocus(); // 키보드 내리기

    await _repo.addComment(songId, content);
    // 댓글 목록 새로고침
    ref.invalidate(commentsProvider(songId));
  }

  @override
  Widget build(BuildContext context) {
    // 플레이어 관련 상태 (기존 코드 참고)
    // 여기서는 UI 레이아웃 위주로 구성합니다.
    final songId = int.parse(widget.mediaItem.id);

    return Scaffold(
      backgroundColor: Colors.black, // 배경색
      body: Stack(
        children: [
          // [1] 배경 그라데이션 (앨범 아트 색상 기반 느낌)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E1E1E), // 짙은 회색
                  Colors.black,
                ],
              ),
            ),
          ),

          // [2] 메인 플레이어 UI (상단)
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                // 상단 바
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text("NOW PLAYING", style: GoogleFonts.chakraPetch(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {}, // 더보기 메뉴
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // 앨범 아트 (크게)
                Hero(
                  tag: 'albumArt_${widget.mediaItem.id}',
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: Offset(0, 10))
                      ],
                      image: DecorationImage(
                        image: NetworkImage(widget.mediaItem.artUri.toString()),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 곡 정보 & 좋아요 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.mediaItem.title,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.mediaItem.artist ?? "Unknown Artist",
                            style: const TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _toggleLike,
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.pinkAccent : Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 진행 바 (Slider) - 실제 연동은 AudioService 필요 (여기선 UI만)
                // _buildProgressBar(),
                // 기존 AudioService 연동 코드를 넣으세요.
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: LinearProgressIndicator(value: 0.3, color: Colors.white, backgroundColor: Colors.white24),
                ),

                const SizedBox(height: 30),

                // 재생 컨트롤 (Play/Pause/Skip)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40), onPressed: () {}),
                    const SizedBox(width: 20),
                    Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      child: IconButton(
                        icon: const Icon(Icons.pause_rounded, color: Colors.black, size: 40),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 40), onPressed: () {}),
                  ],
                ),

                const Spacer(flex: 2), // 하단 여백 확보 (BottomSheet가 올라올 공간)
              ],
            ),
          ),

          // [3] 댓글 섹션 (DraggableScrollableSheet)
          DraggableScrollableSheet(
            initialChildSize: 0.1, // 처음에 보이는 높이 비율 (10%) - "댓글" 핸들만 보임
            minChildSize: 0.1,
            maxChildSize: 0.75, // 최대로 올렸을 때 비율
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF121212).withOpacity(0.95), // 반투명 검정
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, spreadRadius: 5)
                  ],
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: Column(
                  children: [
                    // 핸들 (손잡이)
                    SingleChildScrollView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(height: 12),
                          Text("COMMENTS", style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    // 댓글 리스트
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final commentsAsync = ref.watch(commentsProvider(songId));

                          return commentsAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                            error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.white))),
                            data: (comments) {
                              if (comments.isEmpty) {
                                return const Center(child: Text("첫 번째 댓글을 남겨보세요!", style: TextStyle(color: Colors.white54)));
                              }
                              return ListView.separated(
                                controller: scrollController, // 중요: 드래그 제스처 연동
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: comments.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  final user = comment['users'] ?? {};
                                  final name = user['name'] ?? '알 수 없음';
                                  final cohort = user['cohort'];
                                  final content = comment['content'] ?? '';
                                  final date = DateTime.parse(comment['created_at']); // 날짜 포맷팅 필요 시 추가

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 아바타 (이니셜)
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.grey[800],
                                        child: Text(
                                          name.isNotEmpty ? name[0] : '?',
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // 이름 및 기수 ("12기 김제현")
                                            Row(
                                              children: [
                                                if (cohort != null)
                                                  Container(
                                                    margin: const EdgeInsets.only(right: 6),
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blueAccent.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      "${cohort}기",
                                                      style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                Text(
                                                  name,
                                                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "${date.month}/${date.day} ${date.hour}:${date.minute}",
                                                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            // 댓글 내용
                                            Text(
                                              content,
                                              style: const TextStyle(color: Colors.white, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // 댓글 입력창 (하단 고정)
                    Container(
                      padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 12,
                          bottom: 12 + MediaQuery.of(context).viewInsets.bottom // 키보드 올라오면 같이 올라감
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        border: Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "댓글을 입력하세요...",
                                hintStyle: const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: Colors.black,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _submitComment,
                            icon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}