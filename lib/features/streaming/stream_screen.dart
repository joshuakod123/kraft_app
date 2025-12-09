import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/data/supabase_repository.dart';
import 'audio_service.dart';

// -----------------------------------------------------------------------------
// Providers
// -----------------------------------------------------------------------------
final commentsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, songId) {
  final id = int.tryParse(songId) ?? 0;
  return SupabaseRepository().fetchComments(id);
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

class _StreamScreenState extends ConsumerState<StreamScreen> with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final _repo = SupabaseRepository();

  bool _isLiked = false;
  late AnimationController _playPauseController;

  @override
  void initState() {
    super.initState();
    _playPauseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _loadLikeStatus();
    // 필요 시 자동 재생
    // KraftAudioService.playUrl(widget.mediaItem.id, tag: widget.mediaItem);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _sheetController.dispose();
    _playPauseController.dispose();
    super.dispose();
  }

  void _loadLikeStatus() async {
    final songId = int.tryParse(widget.mediaItem.id) ?? 0;
    final liked = await _repo.isSongLiked(songId);
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    final songId = int.tryParse(widget.mediaItem.id) ?? 0;
    setState(() => _isLiked = !_isLiked);
    await _repo.toggleSongLike(songId);
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final songId = int.tryParse(widget.mediaItem.id) ?? 0;
    _commentController.clear();
    FocusScope.of(context).unfocus(); // 키보드 닫기

    await _repo.addComment(songId, content);
    ref.invalidate(commentsProvider(widget.mediaItem.id));
  }

  @override
  Widget build(BuildContext context) {
    // 키보드 높이 감지
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      // 중요: 키보드가 올라와도 메인 UI(앨범아트 등)가 찌그러지지 않게 함
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. 배경 레이어 (이미지 + 블러 + 그라데이션)
          _buildCinematicBackground(),

          // 2. 메인 플레이어 컨텐츠 (Safe Area 안에서 스크롤 가능하게 하여 오버플로우 완전 방지)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildTopBar(context),
                          // 화면 크기에 따라 여백 유동적 조절
                          SizedBox(height: constraints.maxHeight * 0.05),
                          _buildAlbumArt(),
                          SizedBox(height: constraints.maxHeight * 0.05),
                          _buildSongInfo(),
                          const SizedBox(height: 30),
                          _buildProgressBar(),
                          const SizedBox(height: 10),
                          _buildControls(),
                          // 하단 시트가 올라와도 내용이 보이도록 하단 여백 확보
                          const SizedBox(height: 140),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. 드래그 가능한 댓글 시트 (키보드 패딩 처리 포함)
          _buildGlassBottomSheet(bottomInset),
        ],
      ),
    );
  }

  // --- 🎨 Design Widgets ---

  Widget _buildCinematicBackground() {
    return Stack(
      children: [
        Positioned.fill(
          child: widget.mediaItem.artUri != null
              ? Image.network(
            widget.mediaItem.artUri.toString(),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF111111)),
          )
              : Container(color: const Color(0xFF111111)),
        ),
        // 강력한 블러 (Glass effect)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              color: Colors.black.withOpacity(0.6), // 배경 어둡게 눌러주기
            ),
          ),
        ),
        // 상하단 그라데이션 (텍스트 가독성 확보)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Column(
            children: [
              Text(
                "PLAYING FROM PLAYLIST",
                style: GoogleFonts.roboto(
                    color: Colors.white60, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w500
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Kraft Weekly",
                style: GoogleFonts.notoSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
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
        width: double.infinity,
        // 화면 너비에 맞춰 1:1 비율 유지하되 최대 크기 제한
        constraints: const BoxConstraints(maxWidth: 350, maxHeight: 350, minHeight: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), // 둥근 모서리 약간 줄임 (세련됨)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: -10,
            )
          ],
          image: widget.mediaItem.artUri != null
              ? DecorationImage(
            image: NetworkImage(widget.mediaItem.artUri.toString()),
            fit: BoxFit.cover,
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildSongInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.mediaItem.title,
                style: GoogleFonts.notoSans(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.2
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                widget.mediaItem.artist ?? "Unknown Artist",
                style: GoogleFonts.notoSans(
                    color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w400
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _toggleLike,
          child: Icon(
            _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: _isLiked ? const Color(0xFF1ED760) : Colors.white, // 스포티파이 그린 or 핫핑크 선택 가능
            size: 32,
          ).animate(target: _isLiked ? 1 : 0)
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), curve: Curves.elasticOut),
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

            return Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: position.inMilliseconds.toDouble(),
                    max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                    onChanged: (value) {
                      KraftAudioService.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position), style: GoogleFonts.roboto(color: Colors.white54, fontSize: 12)),
                      Text(_formatDuration(duration), style: GoogleFonts.roboto(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
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
        final playerState = snapshot.data;
        final playing = playerState?.playing;
        final processingState = playerState?.processingState;
        final isPlaying = playing == true && processingState != ProcessingState.completed;

        if (isPlaying) {
          _playPauseController.forward();
        } else {
          _playPauseController.reverse();
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.shuffle, color: Colors.white, size: 24),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 48),
              onPressed: () {},
            ),
            GestureDetector(
              onTap: isPlaying ? KraftAudioService.pause : KraftAudioService.resume,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                    ]
                ),
                child: Center(
                  child: AnimatedIcon(
                    icon: AnimatedIcons.play_pause,
                    progress: _playPauseController,
                    color: Colors.black,
                    size: 36,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 48),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.repeat, color: Colors.white, size: 24),
              onPressed: () {},
            ),
          ],
        );
      },
    );
  }

  // --- 🔥 핵심 Fix: Glassmorphism Bottom Sheet ---

  Widget _buildGlassBottomSheet(double bottomInset) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      // 하단 12%만 빼꼼 보이게 시작
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.92,
      snap: true,
      builder: (BuildContext context, ScrollController scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212).withOpacity(0.85), // 진한 반투명 검정
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Column(
                children: [
                  // --- Drag Handle ---
                  SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 32, height: 4,
                            decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(height: 16),
                          Text("COMMENTS", style: GoogleFonts.notoSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // --- Comment List ---
                  Expanded(
                    child: _buildCommentsList(scrollController),
                  ),

                  // --- Input Field (키보드 패딩 적용) ---
                  _buildInputArea(bottomInset),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentsList(ScrollController scrollController) {
    return Consumer(
      builder: (context, ref, _) {
        final commentsAsync = ref.watch(commentsProvider(widget.mediaItem.id));

        return commentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30)),
          error: (e, s) => const Center(child: Text("댓글 로딩 실패", style: TextStyle(color: Colors.white38))),
          data: (comments) {
            if (comments.isEmpty) {
              return Center(child: Text("가장 먼저 댓글을 남겨보세요.", style: GoogleFonts.notoSans(color: Colors.white38)));
            }
            return ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final c = comments[index];
                final user = c['users'] ?? {};
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white12,
                      backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                      child: user['avatar_url'] == null
                          ? Text((user['name'] ?? "?")[0], style: const TextStyle(color: Colors.white, fontSize: 12))
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(user['name'] ?? "Unknown", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              if (user['cohort'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                                  child: Text("${user['cohort']}기", style: const TextStyle(color: Colors.white, fontSize: 10)),
                                )
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(c['content'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
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

  Widget _buildInputArea(double bottomInset) {
    return Container(
      // 🌟 핵심: 키보드가 올라오면 padding bottom을 키워 입력창을 위로 밀어올림
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 12,
          bottom: bottomInset > 0 ? bottomInset + 12 : 32
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(21),
              ),
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: "댓글 입력...",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _submitComment,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}