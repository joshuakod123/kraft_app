import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 에러 처리용

import '../../core/data/supabase_repository.dart';
import 'audio_service.dart';
import 'player_provider.dart';

// 댓글 Provider
final commentsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, songId) {
  final id = int.tryParse(songId) ?? 0;
  return SupabaseRepository().fetchComments(id);
});

class StreamScreen extends ConsumerStatefulWidget {
  final MediaItem mediaItem;
  const StreamScreen({super.key, required this.mediaItem});

  @override
  ConsumerState<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends ConsumerState<StreamScreen> {
  final TextEditingController _commentController = TextEditingController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final _repo = SupabaseRepository();

  bool _isLiked = false;
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    // 키보드 내리기
    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);

    try {
      final songId = int.tryParse(widget.mediaItem.id) ?? 0;
      await _repo.addComment(songId, content);

      _commentController.clear();
      // 댓글 목록 새로고침
      ref.invalidate(commentsProvider(widget.mediaItem.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 등록되었습니다!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전송 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 키보드 높이
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 100; // 키보드 열림 감지

    return Scaffold(
      backgroundColor: Colors.black,
      // [중요] 키보드가 올라와도 화면 비율을 강제로 줄이지 않음 (우리가 직접 제어)
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. 배경 (초고화질 앨범 아트 + 블러)
          Positioned.fill(
            child: widget.mediaItem.artUri != null
                ? Image.network(widget.mediaItem.artUri.toString(), fit: BoxFit.cover)
                : Container(color: const Color(0xFF111111)),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),

          // 2. 메인 플레이어 컨텐츠
          // 키보드가 올라오면 하단 공간(bottom)을 키보드 높이만큼 밀어줍니다.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: isKeyboardOpen ? bottomInset + 60 : 80, // 60은 입력창 높이
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 현재 사용 가능한 높이
                  final availableHeight = constraints.maxHeight;
                  // 높이가 너무 작으면(키보드 켰을 때) 앨범 아트 숨김 (0px)
                  final artSize = availableHeight < 500 ? 0.0 : availableHeight * 0.4;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          _buildHeader(context),

                          // 앨범 아트 (높이 유동적 조절)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: artSize,
                            width: artSize,
                            margin: EdgeInsets.symmetric(vertical: artSize > 0 ? 20 : 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                if (artSize > 0)
                                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
                              ],
                              image: widget.mediaItem.artUri != null
                                  ? DecorationImage(image: NetworkImage(widget.mediaItem.artUri.toString()), fit: BoxFit.cover)
                                  : null,
                              color: Colors.grey[900],
                            ),
                          ),

                          // 곡 정보
                          _buildSongInfo(),

                          // 재생바와 컨트롤은 공간이 좁으면(키보드 열리면) 숨김
                          if (!isKeyboardOpen) ...[
                            const SizedBox(height: 20),
                            _buildProgressBar(),
                            const SizedBox(height: 10),
                            _buildControls(),
                          ],

                          // 키보드가 열려있으면 댓글 리스트를 메인 화면에 바로 보여줌
                          if (isKeyboardOpen)
                            SizedBox(
                              height: 300, // 리스트 확보
                              child: _buildCommentListWidget(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. 댓글 시트 (키보드가 닫혀있을 때만 보임)
          if (!isKeyboardOpen)
            _buildDraggableCommentSheet(),

          // 4. 댓글 입력창 (키보드 바로 위에 붙음)
          // 여기가 핵심입니다. bottom에 bottomInset을 주어 키보드를 따라다니게 합니다.
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset, // 키보드 높이만큼 올라옴
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.greenAccent,
                        decoration: const InputDecoration(
                          hintText: "Add a comment...",
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isSending ? null : _submitComment,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: _isSending ? Colors.grey : Colors.greenAccent,
                      child: _isSending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 36),
            onPressed: () => ref.read(isPlayerExpandedProvider.notifier).state = false,
          ),
          const Text("NOW PLAYING", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          IconButton(icon: const Icon(Icons.more_vert_rounded, color: Colors.white), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildSongInfo() {
    return Column(
      children: [
        Text(
          widget.mediaItem.title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          widget.mediaItem.artist ?? "Unknown",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 16),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration?>(
      stream: KraftAudioService.durationStream,
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: KraftAudioService.positionStream,
          builder: (context, snapshot) {
            var position = snapshot.data ?? Duration.zero;
            if (position > duration) position = duration;
            return SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: position.inMilliseconds.toDouble(),
                max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                onChanged: (val) => KraftAudioService.seek(Duration(milliseconds: val.toInt())),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControls() {
    return StreamBuilder<PlayerState>(
      stream: KraftAudioService.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40), onPressed: () {}),
            GestureDetector(
              onTap: playing ? KraftAudioService.pause : KraftAudioService.resume,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 32),
              ),
            ),
            IconButton(icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 40), onPressed: () {}),
          ],
        );
      },
    );
  }

  // [수정] 댓글 리스트 위젯
  Widget _buildCommentListWidget() {
    return Consumer(
      builder: (context, ref, _) {
        final commentsAsync = ref.watch(commentsProvider(widget.mediaItem.id));

        return commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return const Center(
                  child: Text(
                      "아직 댓글이 없습니다.\n첫 번째 댓글을 남겨보세요!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, height: 1.5)
                  )
              );
            }

            return ListView.separated(
              // 키보드 올라오면 리스트가 가려지지 않게 패딩 조절
              padding: const EdgeInsets.only(top: 10, bottom: 100, left: 20, right: 20),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final c = comments[index];

                // View를 쓰기 때문에 데이터 접근이 아주 쉬워짐
                final name = c['user_name'] ?? "Unknown";
                final content = c['content'] ?? "";
                final dateStr = c['created_at'];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 프로필 아이콘 (이름 첫 글자)
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _getStringColor(name),
                      child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "?",
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 이름과 내용
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(name, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text(_formatDate(dateStr), style: const TextStyle(color: Colors.white24, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white24)),
          error: (err, stack) => Center(child: Text("로딩 오류: $err", style: const TextStyle(color: Colors.redAccent))),
        );
      },
    );
  }

  // 드래그 가능한 댓글 시트
  Widget _buildDraggableCommentSheet() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.08,
      minChildSize: 0.08,
      maxChildSize: 0.7,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
          ),
          child: Column(
            children: [
              SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 12),
                    const Text("Comments", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              Expanded(
                child: _buildCommentListWidget(), // 위젯 재사용
              ),
              // 키보드 없을 때 입력창 공간 확보용 (입력창은 Stack의 Positioned에 있음)
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // [누락되었던 헬퍼 함수들을 여기 추가했습니다!]
  // ------------------------------------------------------------------

  // 1. 유저 이름에 따라 랜덤한(하지만 고정된) 색상을 반환
  Color _getStringColor(String s) {
    if (s.isEmpty) return Colors.grey;
    final colors = [
      Colors.redAccent, Colors.blueAccent, Colors.greenAccent,
      Colors.orangeAccent, Colors.purpleAccent, Colors.pinkAccent,
      Colors.teal, Colors.indigoAccent
    ];
    return colors[s.hashCode.abs() % colors.length];
  }

  // 2. 날짜 예쁘게 보여주기 (예: '5분 전', '12/25')
  String _formatDate(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final date = DateTime.parse(dateStr).toLocal(); // 한국 시간(로컬)으로 변환
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inSeconds < 60) return "방금 전";
      if (diff.inMinutes < 60) return "${diff.inMinutes}분 전";
      if (diff.inHours < 24) return "${diff.inHours}시간 전";
      return "${date.month}/${date.day}"; // 날짜 표시
    } catch (e) {
      return "";
    }
  }
}