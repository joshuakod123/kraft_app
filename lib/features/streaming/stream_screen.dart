import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/data/supabase_repository.dart';
import 'audio_service.dart';
import 'player_provider.dart';

// 댓글 리스트 Provider
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

class _StreamScreenState extends ConsumerState<StreamScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final _repo = SupabaseRepository();

  bool _isLiked = false;
  int _likeCount = 0; // [New] 좋아요 갯수 상태
  bool _isSending = false;
  bool _showComments = false;

  String? _currentUserId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void didUpdateWidget(covariant StreamScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaItem.id != widget.mediaItem.id) {
      _initData();
      if (_showComments) setState(() => _showComments = false);
    }
  }

  Future<void> _initData() async {
    _checkUserPermissions();
    _checkLikeStatus();
    _fetchLikeCount(); // [New] 갯수 가져오기
  }

  Future<void> _checkUserPermissions() async {
    final userId = _repo.currentUserId;
    final isAdmin = await _repo.isAdmin();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _isAdmin = isAdmin;
      });
    }
  }

  Future<void> _checkLikeStatus() async {
    final songId = int.tryParse(widget.mediaItem.id) ?? 0;
    final liked = await _repo.isSongLiked(songId);
    if (mounted) setState(() => _isLiked = liked);
  }

  // [New] 좋아요 갯수 서버에서 가져오기
  Future<void> _fetchLikeCount() async {
    final songId = int.tryParse(widget.mediaItem.id) ?? 0;
    final count = await _repo.getSongLikeCount(songId);
    if (mounted) setState(() => _likeCount = count);
  }

  Future<void> _toggleLike() async {
    final songId = int.tryParse(widget.mediaItem.id) ?? 0;

    // [UI] 낙관적 업데이트 (서버 응답 기다리지 않고 즉시 반영)
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
      if (_likeCount < 0) _likeCount = 0; // 방어 코드
    });

    final success = await _repo.toggleSongLike(songId);

    // 실패 시 롤백
    if (!success && mounted) {
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);

    try {
      final songId = int.tryParse(widget.mediaItem.id) ?? 0;
      await _repo.addComment(songId, content);

      _commentController.clear();

      // [Fix] 댓글 작성 후 Provider를 강제로 새로고침하여 즉시 반영
      // refresh는 dispose 후 다시 create 하므로 최신 데이터를 가져옵니다.
      ref.refresh(commentsProvider(widget.mediaItem.id));

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      await _repo.deleteComment(commentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 삭제되었습니다.'), duration: Duration(seconds: 1)),
        );
        // 삭제 후에도 리스트 갱신
        ref.refresh(commentsProvider(widget.mediaItem.id));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  void _toggleCommentMode() {
    setState(() {
      _showComments = !_showComments;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.mediaItem.artUri != null
                ? Image.network(widget.mediaItem.artUri.toString(), fit: BoxFit.cover)
                : Container(color: const Color(0xFF111111)),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withOpacity(0.7)),
            ),
          ),
          Positioned.fill(
            top: 0,
            bottom: _showComments ? bottomInset : 0,
            child: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: _showComments ? _buildCommentModeLayout() : _buildPlayerModeLayout(),
              ),
            ),
          ),
          if (!_showComments)
            Positioned(
              top: 50, left: 20,
              child: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 36),
                onPressed: () => ref.read(isPlayerExpandedProvider.notifier).state = false,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerModeLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
                image: widget.mediaItem.artUri != null
                    ? DecorationImage(image: NetworkImage(widget.mediaItem.artUri.toString()), fit: BoxFit.cover)
                    : null,
                color: Colors.grey[900],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(widget.mediaItem.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(widget.mediaItem.artist ?? "Unknown", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // [UI Change] 좋아요 버튼 + 숫자 표시
              Column(
                children: [
                  IconButton(
                    icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.redAccent : Colors.white, size: 28),
                    onPressed: _toggleLike,
                  ),
                  Text(
                      "$_likeCount",
                      style: TextStyle(color: _isLiked ? Colors.redAccent : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ],
              ),

              StreamBuilder<PlayerState>(
                stream: KraftAudioService.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return GestureDetector(
                    onTap: playing ? KraftAudioService.pause : KraftAudioService.resume,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 40),
                    ),
                  );
                },
              ),

              // 댓글 버튼
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 28),
                    onPressed: _toggleCommentMode,
                  ),
                  const Text("Chat", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressBar(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCommentModeLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: _toggleCommentMode,
              ),
              const Expanded(
                child: Text("Comments", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final commentsAsync = ref.watch(commentsProvider(widget.mediaItem.id));
              return commentsAsync.when(
                data: (comments) {
                  if (comments.isEmpty) return const Center(child: Text("첫 번째 댓글을 남겨보세요!", style: TextStyle(color: Colors.white54)));
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _buildCommentItem(comments[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.red))),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "댓글 입력...", hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true, fillColor: Colors.black54,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.greenAccent),
                onPressed: _isSending ? null : _submitComment,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> c) {
    final commentId = c['id'] as int;
    final userId = c['user_id'] as String;
    final content = c['content'] ?? "";
    final date = _formatDate(c['created_at']);

    // [Check] Users Join Data Handling
    final userData = c['users']; // users가 Map일 수도, 아닐 수도 있음 체크
    String name = "Unknown";
    int cohort = 0;

    if (userData is Map<String, dynamic>) {
      name = userData['name'] ?? "Unknown";
      cohort = userData['cohort'] ?? 0;
    } else if (userData is List && userData.isNotEmpty) { // 가끔 List로 올 수 있음
      name = userData[0]['name'] ?? "Unknown";
      cohort = userData[0]['cohort'] ?? 0;
    }

    final bool canDelete = (_currentUserId == userId) || _isAdmin;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.primaries[name.hashCode % Colors.primaries.length],
          child: Text(name.isNotEmpty ? name[0] : "?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$cohort기 $name",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Row(
                    children: [
                      Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      if (canDelete) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showDeleteConfirmDialog(commentId),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog(int commentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text("댓글 삭제", style: TextStyle(color: Colors.white)),
        content: const Text("정말로 이 댓글을 삭제하시겠습니까?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteComment(commentId);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
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
              data: SliderThemeData(trackHeight: 2, activeTrackColor: Colors.white, inactiveTrackColor: Colors.white24, thumbColor: Colors.white, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14)),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "";
    final date = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return "방금";
    if (diff.inMinutes < 60) return "${diff.inMinutes}분 전";
    if (diff.inHours < 24) return "${diff.inHours}시간 전";
    return "${date.month}/${date.day}";
  }
}