import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:ui'; // Glassmorphism을 위한 임포트

import '../../core/data/supabase_repository.dart';

// -----------------------------------------------------------------------------
// Providers (데이터 관리)
// -----------------------------------------------------------------------------

// 댓글 목록 가져오기 Provider (songId 기반)
// autoDispose를 사용하여 화면을 나갈 때 데이터를 정리하여 메모리 누수 방지 및 최신 상태 유지
final commentsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, songId) {
  return SupabaseRepository().fetchComments(songId as int);
});

// -----------------------------------------------------------------------------
// UI Screen
// -----------------------------------------------------------------------------

class StreamScreen extends ConsumerStatefulWidget {
  final MediaItem mediaItem;

  const StreamScreen({super.key, required this.mediaItem});

  @override
  ConsumerState<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends ConsumerState<StreamScreen> {
  final TextEditingController _commentController = TextEditingController();
  final _repo = SupabaseRepository();
  bool _isLiked = false;
  // 드래그 가능한 시트의 컨트롤러
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // 좋아요 초기 상태 로드
  void _loadLikeStatus() async {
    final liked = await _repo.isSongLiked(widget.mediaItem.id as int);
    if (mounted) {
      setState(() => _isLiked = liked);
    }
  }

  // 좋아요 토글 액션
  Future<void> _toggleLike() async {
    // 낙관적 업데이트: 서버 응답 기다리지 않고 UI 먼저 변경하여 반응성 향상
    setState(() => _isLiked = !_isLiked);
    // 실제 DB 요청
    await _repo.toggleSongLike(widget.mediaItem.id as int);
  }

  // 댓글 전송 액션
  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    _commentController.clear();
    FocusScope.of(context).unfocus(); // 키보드 내리기

    // DB 전송
    await _repo.addComment(widget.mediaItem.id as int, content);

    // 리스트 새로고침 (invalidate를 호출하면 provider가 다시 데이터를 받아옴)
    ref.invalidate(commentsProvider(widget.mediaItem.id));
  }

  @override
  Widget build(BuildContext context) {
    // 화면 높이 계산 (반응형 UI를 위해)
    final screenHeight = MediaQuery.of(context).size.height;
    // 키보드가 올라왔을 때 바텀시트가 가려지지 않게 하기 위한 패딩
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      // 키보드가 올라올 때 화면이 찌그러지는 것을 방지
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // [Layer 1: 배경 이미지 및 블러 효과]
          _buildBackground(),

          // [Layer 2: 메인 플레이어 컨텐츠 (스크롤 가능)]
          Positioned.fill(
            child: SingleChildScrollView(
              // 작은 화면에서도 내용이 잘리지 않도록 스크롤 뷰로 감쌈
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                // 최소 높이를 화면 높이로 설정하여 내용이 적어도 꽉 차보이게 함
                height: screenHeight,
                child: SafeArea(
                  child: Column(
                    children: [
                      // 2.1 상단 네비게이션 바
                      _buildAppBar(context),

                      const Spacer(flex: 1),

                      // 2.2 앨범 아트 (Hero 애니메이션 적용)
                      _buildAlbumArt(),

                      const SizedBox(height: 40),

                      // 2.3 곡 정보 및 좋아요 버튼
                      _buildSongInfoAndLike(),

                      const SizedBox(height: 30),

                      // 2.4 재생 진행 바 (더미 데이터)
                      _buildProgressBar(),

                      const SizedBox(height: 20),

                      // 2.5 재생 컨트롤 버튼
                      _buildPlaybackControls(),

                      // 하단 댓글 시트가 올라올 공간 확보
                      const Spacer(flex: 2),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // [Layer 3: 슬라이딩 댓글 패널 (DraggableScrollableSheet)]
          _buildCommentsSheet(bottomPadding),
        ],
      ),
    );
  }

  // --- Widget Builder Methods (코드를 깔끔하게 분리) ---

  Widget _buildBackground() {
    return Stack(
      children: [
        if (widget.mediaItem.artUri != null)
          Positioned.fill(
            child: Image.network(
              widget.mediaItem.artUri.toString(),
              fit: BoxFit.cover,
              // 이미지 로딩 실패 시 검은 배경
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
            ),
          ),
        // 강력한 블러 효과로 분위기 연출
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "NOW PLAYING",
            style: GoogleFonts.chakraPetch(
              color: Colors.white70,
              fontSize: 13,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          // 더보기 버튼 (추후 기능 구현용)
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Hero(
      tag: 'albumArt_${widget.mediaItem.id}',
      child: Container(
        // 화면 크기에 비례하여 사이즈 조절
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxWidth: 350, maxHeight: 350),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 15),
              spreadRadius: -5,
            )
          ],
          image: widget.mediaItem.artUri != null
              ? DecorationImage(
            image: NetworkImage(widget.mediaItem.artUri.toString()),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: widget.mediaItem.artUri == null
            ? const Icon(Icons.music_note_rounded, size: 120, color: Colors.white12)
            : null,
      ),
    );
  }

  Widget _buildSongInfoAndLike() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mediaItem.title,
                  style: GoogleFonts.notoSans(
                      color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.mediaItem.artist ?? "Unknown Artist",
                  style: GoogleFonts.notoSans(
                      color: Colors.white54, fontSize: 17, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 좋아요 버튼 (애니메이션 효과 추가 가능)
          GestureDetector(
            onTap: _toggleLike,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isLiked ? Colors.pinkAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isLiked ? Colors.pinkAccent : Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    // 실제 구현 시 AudioService의 스트림과 연동 필요
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.3, // 더미 값
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("1:24", style: TextStyle(color: Colors.white38, fontSize: 12)),
              Text("4:30", style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.shuffle_rounded, color: Colors.white38, size: 28),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 42),
          onPressed: () {},
        ),
        // 재생/일시정지 버튼 강조
        Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 20)],
          ),
          child: IconButton(
            icon: const Icon(Icons.pause_rounded, color: Colors.black, size: 40),
            onPressed: () {},
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 42),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.repeat_rounded, color: Colors.white38, size: 28),
          onPressed: () {},
        ),
      ],
    );
  }

  // [핵심 UI] 슬라이딩 댓글 패널
  Widget _buildCommentsSheet(double bottomPadding) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.08, // 처음에는 핸들만 살짝 보이게 (8%)
      minChildSize: 0.08,     // 최소 높이
      maxChildSize: 0.85,     // 최대 높이 (화면의 85%)
      snap: true,             // 놓았을 때 특정 위치로 달라붙는 효과
      snapSizes: const [0.08, 0.5, 0.85], // 달라붙을 위치 지점들
      builder: (BuildContext context, ScrollController scrollController) {
        // Glassmorphism 효과를 위한 ClipRRect + BackdropFilter
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withOpacity(0.9), // 약간 투명한 검은색 배경
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
              ),
              child: Column(
                children: [
                  // 3.1 패널 핸들 및 헤더
                  _buildSheetHeader(scrollController),

                  // 3.2 댓글 리스트 (스크롤 가능 영역)
                  Expanded(
                    child: _buildCommentsList(scrollController),
                  ),

                  // 3.3 댓글 입력창 (키보드 올라오면 같이 올라감)
                  _buildCommentInput(bottomPadding),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetHeader(ScrollController scrollController) {
    // SingleChildScrollView를 써야 DraggableScrollableSheet가 드래그 제스처를 인식함
    return SingleChildScrollView(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // 드래그 핸들 바
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "COMMENTS",
            style: GoogleFonts.chakraPetch(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
        ],
      ),
    );
  }

  Widget _buildCommentsList(ScrollController scrollController) {
    return Consumer(
      builder: (context, ref, child) {
        final commentsAsync = ref.watch(commentsProvider(widget.mediaItem.id));

        return commentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (err, stack) => Center(child: Text('Error 로딩 실패', style: TextStyle(color: Colors.white54))),
          data: (comments) {
            if (comments.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: Colors.white24, size: 40),
                    SizedBox(height: 16),
                    Text("아직 댓글이 없습니다.\n첫 번째 댓글을 남겨보세요!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54)
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              controller: scrollController, // 중요: 이 컨트롤러를 연결해야 시트와 리스트 스크롤이 연동됨
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80), // 하단 여백 확보
              itemCount: comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final comment = comments[index];
                final user = comment['users'] ?? {};
                final name = user['name'] ?? '알 수 없음';
                final cohort = user['cohort']; // 기수 정보
                final content = comment['content'] ?? '';
                final initial = name.isNotEmpty ? name[0] : '?';
                // final date = DateTime.parse(comment['created_at']); // 날짜 필요시 사용

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 유저 아바타 (이니셜)
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 이름 및 기수 표시 영역
                          Row(
                            children: [
                              if (cohort != null)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5), width: 0.5)
                                  ),
                                  child: Text(
                                    "${cohort}기",
                                    style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              Text(
                                name,
                                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              // 더보기 아이콘 (삭제/신고 등 추후 구현)
                              Icon(Icons.more_horiz, color: Colors.white24, size: 18),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 댓글 내용
                          Text(
                            content,
                            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
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
    );
  }

  Widget _buildCommentInput(double bottomPadding) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        // 키보드 높이만큼 패딩을 주어 입력창이 가려지지 않게 함
        bottom: 20 + bottomPadding,
      ),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))
          ]
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              cursorColor: Theme.of(context).primaryColor,
              decoration: InputDecoration(
                hintText: "댓글을 입력하세요...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 전송 버튼
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            child: IconButton(
              icon: Icon(Icons.send_rounded, color: Theme.of(context).primaryColor, size: 22),
              onPressed: _submitComment,
            ),
          ),
        ],
      ),
    );
  }
}