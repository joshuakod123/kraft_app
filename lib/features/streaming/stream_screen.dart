import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

class _StreamScreenState extends ConsumerState<StreamScreen> with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final _repo = SupabaseRepository();

  bool _isLiked = false;

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

  void _loadLikeStatus() async {
    final songId = int.tryParse(widget.mediaItem.id) ?? 0;
    if (songId == 0) return;
    final liked = await _repo.isSongLiked(songId);
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    final songId = int.tryParse(widget.mediaItem.id) ?? 0;
    if (songId == 0) return;
    setState(() => _isLiked = !_isLiked);
    await _repo.toggleSongLike(songId);
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final songId = int.tryParse(widget.mediaItem.id) ?? 0;
    _commentController.clear();
    FocusScope.of(context).unfocus(); // 키보드 내리기

    try {
      await _repo.addComment(songId, content);
      ref.invalidate(commentsProvider(widget.mediaItem.id));
    } catch (e) {
      debugPrint("Error posting comment: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 키보드 높이
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    // 화면 전체 높이
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          // 1. 배경 (Blur)
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

          // 2. 메인 컨텐츠 (핵심 수정: LayoutBuilder + SingleChildScrollView)
          // 이 구조가 오버플로우를 막아줍니다.
          Positioned.fill(
            bottom: 80, // 하단 댓글 시트가 살짝 보일 공간 확보
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    // 내용이 적어도 화면 꽉 차게, 내용이 많으면 스크롤되게
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 공간 배분
                          children: [
                            _buildTopBar(context),
                            // 화면이 작을땐 간격을 줄이도록 유동적으로 처리
                            SizedBox(height: screenHeight * 0.02),
                            _buildAlbumArt(screenHeight),
                            SizedBox(height: screenHeight * 0.03),
                            _buildSongInfo(),
                            const SizedBox(height: 20),
                            _buildProgressBar(),
                            const SizedBox(height: 10),
                            _buildControls(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. 댓글 시트
          _buildCommentsSheet(bottomInset),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
          onPressed: () {
            ref.read(isPlayerExpandedProvider.notifier).state = false;
          },
        ),
        Column(
          children: [
            Text("PLAYING FROM PLAYLIST", style: GoogleFonts.roboto(color: Colors.white60, fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text("Kraft Weekly", style: GoogleFonts.notoSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
      ],
    );
  }

  Widget _buildAlbumArt(double screenHeight) {
    // 화면 높이에 따라 앨범 아트 크기 조절 (최대 350, 최소 200)
    double artSize = screenHeight * 0.4;
    if (artSize > 350) artSize = 350;
    if (artSize < 200) artSize = 200;

    return SizedBox(
      height: artSize,
      width: artSize, // 정사각형 유지
      child: Hero(
        tag: 'albumArt_${widget.mediaItem.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20, offset: const Offset(0, 10))],
            image: widget.mediaItem.artUri != null
                ? DecorationImage(image: NetworkImage(widget.mediaItem.artUri.toString()), fit: BoxFit.cover)
                : null,
            color: Colors.grey[900],
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.mediaItem.title,
                style: GoogleFonts.notoSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                widget.mediaItem.artist ?? "Unknown",
                style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 18),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _toggleLike,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isLiked ? const Color(0xFF1ED760) : Colors.white,
              size: 32,
            ).animate(target: _isLiked ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), curve: Curves.elasticOut),
          ),
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

            // Slider 대체 구현 (심플 버전)
            return Column(
              children: [
                SizedBox(
                  height: 20,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: position.inMilliseconds.toDouble(),
                      max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                      onChanged: (val) {
                        KraftAudioService.seek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(_formatDuration(duration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
        final playing = snapshot.data?.playing ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(icon: const Icon(Icons.shuffle, color: Colors.white), onPressed: () {}),
            IconButton(icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 42), onPressed: () {}),
            GestureDetector(
              onTap: playing ? KraftAudioService.pause : KraftAudioService.resume,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 32),
              ),
            ),
            IconButton(icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 42), onPressed: () {}),
            IconButton(icon: const Icon(Icons.repeat, color: Colors.white), onPressed: () {}),
          ],
        );
      },
    );
  }

  Widget _buildCommentsSheet(double bottomInset) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.85,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, -4))],
          ),
          child: Column(
            children: [
              SingleChildScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    Text("COMMENTS", style: GoogleFonts.notoSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final comments = ref.watch(commentsProvider(widget.mediaItem.id));
                    return comments.when(
                      data: (data) => data.isEmpty
                          ? const Center(child: Text("No comments yet.", style: TextStyle(color: Colors.white54)))
                          : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: data.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final c = data[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(radius: 14, backgroundColor: Colors.grey[800], child: Text((c['users']?['name']??"?")[0], style: const TextStyle(color: Colors.white, fontSize: 12))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c['users']?['name'] ?? "Unknown", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(c['content'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                      error: (_, __) => const SizedBox(),
                    );
                  },
                ),
              ),

              // 키보드 대응 입력창
              Container(
                padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: bottomInset > 0 ? bottomInset + 12 : 32),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white12)), color: Color(0xFF1E1E1E)),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                          decoration: const InputDecoration(
                            hintText: "Add a comment...",
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white), onPressed: _submitComment),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}