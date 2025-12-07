import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // GoRouter import 추가
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';

// [1] 게시글 목록 Provider
final communityListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return SupabaseRepository().getCommunityPostsWithUser();
});

// [Helper] 사용자 정보 포맷팅 함수
String formatUserInfo(Map<String, dynamic>? user) {
  if (user == null) return "Unknown User";

  String name = user['name'] ?? '익명';
  String schoolFull = user['school'] ?? '';
  String school = '';

  if (schoolFull.contains('서울')) school = '서울';
  else if (schoolFull.contains('연세')) school = '연세';
  else if (schoolFull.contains('고려')) school = '고려';
  else school = schoolFull;

  String studentId = user['student_id'] ?? '';
  final idMatch = RegExp(r'\d+').firstMatch(studentId);
  String idNum = idMatch != null ? idMatch.group(0)! : studentId;

  String major = user['major'] ?? '';
  String role = user['role'] == 'manager' ? '임원' : '회원';

  return "$name/$school$idNum/$major/$role";
}

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  void _showNeonWriteModal(BuildContext context, WidgetRef ref, Color themeColor) {
    // ... (기존과 동일, 생략 가능하지만 복붙 편의를 위해 유지)
    final contentCtrl = TextEditingController();
    String selectedCategory = 'General';
    final categories = ['General', 'Question', 'Notice', 'Free'];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Write",
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("NEW SIGNAL", style: GoogleFonts.chakraPetch(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: themeColor, blurRadius: 20)])),
                            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32)),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Wrap(
                          spacing: 12,
                          children: categories.map((cat) {
                            final isSelected = selectedCategory == cat;
                            return GestureDetector(
                              onTap: () => setState(() => selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(color: isSelected ? themeColor.withOpacity(0.8) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? themeColor : Colors.white24, width: 1.5)),
                                child: Text(cat, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 30),
                        GlassContainer(
                          height: 300, width: double.infinity, borderRadius: BorderRadius.circular(24), borderWidth: 1.5, borderColor: themeColor.withOpacity(0.3),
                          gradient: LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          blur: 20,
                          child: TextField(
                            controller: contentCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
                            maxLines: null, keyboardType: TextInputType.multiline, cursorColor: themeColor,
                            decoration: InputDecoration(hintText: 'Type your message here...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 18), border: InputBorder.none, contentPadding: const EdgeInsets.all(24)),
                          ),
                        ),
                        const SizedBox(height: 40),
                        GestureDetector(
                          onTap: () async {
                            if (contentCtrl.text.trim().isNotEmpty) {
                              final success = await SupabaseRepository().addCommunityPost(contentCtrl.text.trim(), selectedCategory);
                              if (success && context.mounted) {
                                Navigator.pop(context);
                                ref.invalidate(communityListProvider);
                              }
                            }
                          },
                          child: Container(
                            height: 60, decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: themeColor.withOpacity(0.6), blurRadius: 20, spreadRadius: 2)]),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("BROADCAST SIGNAL", style: GoogleFonts.chakraPetch(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(width: 10), const Icon(Icons.sensors, color: Colors.black)]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dept = ref.watch(currentDeptProvider);
    final themeColor = dept.color;
    final postsAsync = ref.watch(communityListProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('COMMUNITY', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => _showNeonWriteModal(context, ref, themeColor),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: themeColor.withOpacity(0.5), width: 1.5)),
                child: Row(children: [Icon(Icons.edit, color: themeColor, size: 18), const SizedBox(width: 8), Text("WRITE", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12))]),
              ),
            ),
          )
        ],
      ),
      body: postsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: themeColor)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(child: Text("NO SIGNALS DETECTED", style: GoogleFonts.chakraPetch(color: Colors.white30, fontSize: 18)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(communityListProvider),
            color: themeColor,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _PostCard(post: posts[index], themeColor: themeColor),
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final Map<String, dynamic> post;
  final Color themeColor;

  const _PostCard({required this.post, required this.themeColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateTime.parse(post['created_at']).toLocal();
    final formattedDate = DateFormat('MM.dd HH:mm').format(date);

    final String content = post['content'] ?? '';
    final String title = content.split('\n').first;
    final String writerName = post['users']?['name'] ?? 'Unknown';

    return GestureDetector(
      onTap: () {
        // [수정: 문제 3 해결] Navigator.push 대신 context.push를 사용하여 Router 상태 유지
        context.push('/community/detail', extra: post);
      },
      child: GlassContainer(
        // [수정: 문제 1 해결] 고정 높이(height) 제거하여 텍스트 길이에 따라 늘어나게 함
        width: double.infinity,
        borderRadius: BorderRadius.circular(20),
        borderWidth: 1.0, borderColor: Colors.white.withOpacity(0.08),
        blur: 10,
        gradient: LinearGradient(colors: [const Color(0xFF1A1A1A).withOpacity(0.8), const Color(0xFF0F0F0F).withOpacity(0.9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: themeColor.withOpacity(0.1), border: Border.all(color: themeColor.withOpacity(0.4)), borderRadius: BorderRadius.circular(8)),
                    child: Text(post['category'] ?? 'General', style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  Text(writerName, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),

              // [수정: 문제 1 해결] 제목 영역 maxLines를 2로 늘림
              Text(
                title,
                style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2, // 1줄에서 2줄로 변경
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12), // 날짜와 간격 추가
              Align(
                alignment: Alignment.bottomRight,
                child: Text(formattedDate, style: const TextStyle(color: Colors.white24, fontSize: 11)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// [상세 페이지 - 클래스 이름을 PostDetailScreen으로 변경하여 Router에서 접근 가능하게 함]
class PostDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  Future<void> _loadLikeStatus() async {
    final liked = await SupabaseRepository().hasUserLiked(widget.post['id']);
    final count = await SupabaseRepository().getLikeCount(widget.post['id']);
    if (mounted) setState(() { _isLiked = liked; _likeCount = count; });
  }

  Future<void> _toggleLike() async {
    setState(() { _isLiked = !_isLiked; _likeCount += _isLiked ? 1 : -1; });
    await SupabaseRepository().toggleLike(widget.post['id']);
  }

  Future<List<Map<String, dynamic>>> _fetchComments() => SupabaseRepository().getCommentsWithUser(widget.post['id']);

  @override
  Widget build(BuildContext context) {
    final userInfo = formatUserInfo(widget.post['users']);
    final isManager = ref.watch(isManagerProvider);
    final dept = ref.watch(currentDeptProvider);
    final themeColor = dept.color; // Provider에서 색상 가져옴

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black, foregroundColor: Colors.white,
        actions: [
          if (isManager)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                await SupabaseRepository().deleteCommunityPost(widget.post['id']);
                if (mounted) {
                  ref.invalidate(communityListProvider);
                  context.pop(); // Navigator.pop 대신 context.pop 사용
                }
              },
            )
        ],
      ),
      body: Stack( // [수정: 문제 2 해결] Stack을 사용하여 입력창 위치 제어
        children: [
          // 1. 스크롤 가능한 컨텐츠 영역
          Positioned.fill(
            child: SingleChildScrollView(
              // 하단 패딩을 넉넉히 주어 입력창 뒤로 글이 숨지 않게 함 (Nav bar 높이 + 입력창 높이 고려)
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: themeColor)),
                    child: Text(widget.post['category'] ?? 'General', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      CircleAvatar(radius: 18, backgroundColor: Colors.grey[800], child: const Icon(Icons.person, size: 20, color: Colors.white)),
                      const SizedBox(width: 12),
                      Text(userInfo, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Text(
                    widget.post['content'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 40),

                  Center(
                    child: GestureDetector(
                      onTap: _toggleLike,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(color: _isLiked ? themeColor.withOpacity(0.2) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30), border: Border.all(color: _isLiked ? themeColor : Colors.white24)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? themeColor : Colors.white70, size: 20).animate(target: _isLiked ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
                            const SizedBox(width: 8),
                            Text("$_likeCount Likes", style: TextStyle(color: _isLiked ? themeColor : Colors.white70, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  const Text("COMMENTS", style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchComments(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final comments = snapshot.data!;
                      if (comments.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No comments yet.", style: TextStyle(color: Colors.white24))));

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          final commentUserInfo = formatUserInfo(comment['users']);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.subdirectory_arrow_right, size: 16, color: themeColor.withOpacity(0.5)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(commentUserInfo, style: TextStyle(color: themeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text(comment['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                ],
              ),
            ),
          ),

          // [수정: 문제 2 해결] 댓글 입력창을 화면 하단에 고정하되, Nav Bar 위로 올림
          Positioned(
            left: 0,
            right: 0,
            bottom: 0, // 기본적으로 바닥에 붙임
            child: Container(
              // [중요] padding bottom을 90으로 주어 플로팅 네비게이션 바 위로 올라오게 함
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.black.withOpacity(0.0)],
                  stops: const [0.6, 1.0],
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E), // 배경색을 줘서 겹쳐도 보이게
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TextField(
                      controller: _commentCtrl,
                      cursorColor: themeColor,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...', hintStyle: const TextStyle(color: Colors.white30),
                        filled: true, fillColor: Colors.transparent,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: themeColor.withOpacity(0.5))),
                      ),
                    ),
                  )),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () async {
                      if (_commentCtrl.text.trim().isNotEmpty) {
                        await SupabaseRepository().addComment(widget.post['id'], _commentCtrl.text.trim());
                        _commentCtrl.clear();
                        setState(() {});
                      }
                    },
                    icon: CircleAvatar(backgroundColor: themeColor, radius: 22, child: const Icon(Icons.arrow_upward, color: Colors.black, size: 22)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}