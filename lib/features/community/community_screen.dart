import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';
// import '../../core/constants/department_enum.dart'; // 필요 시

// [1] 게시글 목록 Provider (자동 캐싱 & 리프레시)
final communityListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return SupabaseRepository().getCommunityPostsWithUser();
});

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  // [3] 혁신적인 풀스크린 글쓰기 UI (Neon Glassmorphism)
  void _showNeonWriteModal(BuildContext context, WidgetRef ref, Color themeColor) {
    final contentCtrl = TextEditingController();
    String selectedCategory = 'General';
    final categories = ['General', 'Question', 'Notice', 'Free'];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Write",
      barrierColor: Colors.black.withOpacity(0.9), // 배경을 더 어둡게 처리하여 집중도 향상
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: StatefulBuilder(
            builder: (context, setState) {
              return Stack(
                children: [
                  // 배경: 은은한 부서 색상 글로우 효과
                  Positioned(
                    top: -100, right: -100,
                    child: Container(
                      width: 300, height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeColor.withOpacity(0.2),
                        boxShadow: [BoxShadow(color: themeColor, blurRadius: 150, spreadRadius: 50)],
                      ),
                    ),
                  ),

                  Center(
                    child: SingleChildScrollView(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 상단 헤더
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "NEW SIGNAL",
                                  style: GoogleFonts.chakraPetch(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [Shadow(color: themeColor, blurRadius: 20)],
                                  ),
                                ).animate().fadeIn().slideX(),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),

                            // 카테고리 선택 (네온 버튼 스타일)
                            Wrap(
                              spacing: 12,
                              children: categories.map((cat) {
                                final isSelected = selectedCategory == cat;
                                return GestureDetector(
                                  onTap: () => setState(() => selectedCategory = cat),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? themeColor.withOpacity(0.8) : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? themeColor : Colors.white24,
                                        width: 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [BoxShadow(color: themeColor.withOpacity(0.6), blurRadius: 12)]
                                          : [],
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ).animate().fadeIn(delay: 100.ms),

                            const SizedBox(height: 30),

                            // 텍스트 입력창 (유리 질감)
                            GlassContainer(
                              height: 300,
                              width: double.infinity,
                              borderRadius: BorderRadius.circular(24),
                              borderWidth: 1.5,
                              borderColor: themeColor.withOpacity(0.3),
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              blur: 20,
                              child: TextField(
                                controller: contentCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                cursorColor: themeColor,
                                decoration: InputDecoration(
                                  hintText: 'Type your message here...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 18),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(24),
                                ),
                              ),
                            ).animate().fadeIn(delay: 200.ms).scale(),

                            const SizedBox(height: 40),

                            // 전송 버튼 (네온 효과)
                            GestureDetector(
                              onTap: () async {
                                if (contentCtrl.text.trim().isNotEmpty) {
                                  // 서버 전송
                                  final success = await SupabaseRepository().addCommunityPost(
                                    contentCtrl.text.trim(),
                                    selectedCategory,
                                  );

                                  if (success && context.mounted) {
                                    Navigator.pop(context);
                                    // [핵심] 리스트 새로고침
                                    ref.invalidate(communityListProvider);
                                  }
                                }
                              },
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: themeColor.withOpacity(0.6), blurRadius: 20, spreadRadius: 2)
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "BROADCAST SIGNAL",
                                      style: GoogleFonts.chakraPetch(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.sensors, color: Colors.black),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10 * anim1.value, sigmaY: 10 * anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // [2] 부서별 색상 적용 (Directing -> Red)
    final dept = ref.watch(currentDeptProvider);
    final themeColor = dept.color;

    final postsAsync = ref.watch(communityListProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('COMMUNITY', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
        centerTitle: false,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // 글쓰기 버튼 (부서 색상 적용)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => _showNeonWriteModal(context, ref, themeColor),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: themeColor.withOpacity(0.5), width: 1.5),
                  boxShadow: [BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: themeColor, size: 18),
                    const SizedBox(width: 8),
                    Text("WRITE", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_tethering_off, size: 60, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text("NO SIGNALS DETECTED", style: GoogleFonts.chakraPetch(color: Colors.white30, fontSize: 18)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(communityListProvider),
            color: themeColor,
            backgroundColor: Colors.grey[900],
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _PostCard(post: posts[index], themeColor: themeColor);
              },
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
    final isManager = ref.watch(isManagerProvider);
    final date = DateTime.parse(post['created_at']).toLocal();
    final formattedDate = DateFormat('MM.dd HH:mm').format(date);
    final userName = post['users']?['name'] ?? 'Unknown';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => _PostDetailScreen(post: post, themeColor: themeColor)),
        );
      },
      child: GlassContainer(
        height: 160,
        width: double.infinity,
        borderRadius: BorderRadius.circular(24),
        borderWidth: 1.0,
        borderColor: Colors.white.withOpacity(0.08),
        blur: 10,
        elevation: 0,
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A1A).withOpacity(0.8),
            const Color(0xFF0F0F0F).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 카테고리 + 유저 + 삭제버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          border: Border.all(color: themeColor.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          post['category'] ?? 'General',
                          style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(userName, style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  if (isManager)
                    GestureDetector(
                      onTap: () async {
                        // 삭제 로직 (생략 - 동일)
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            title: const Text("Delete Signal", style: TextStyle(color: Colors.white)),
                            content: const Text("Permanently delete this post?", style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await SupabaseRepository().deleteCommunityPost(post['id']);
                          ref.invalidate(communityListProvider);
                        }
                      },
                      child: Icon(Icons.delete_forever_rounded, color: Colors.redAccent.withOpacity(0.7), size: 22),
                    )
                ],
              ),
              const SizedBox(height: 16),

              // 본문
              Expanded(
                child: Text(
                  post['content'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 푸터: 날짜 + 댓글 유도
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mode_comment_outlined, size: 16, color: Colors.white.withOpacity(0.3)),
                      const SizedBox(width: 6),
                      Text("Reply", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                    ],
                  ),
                  Text(formattedDate, style: const TextStyle(color: Colors.white24, fontSize: 12)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// [상세 페이지] _PostDetailScreen은 이전과 로직 동일, 테마 컬러만 전달받아 사용
class _PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final Color themeColor;
  const _PostDetailScreen({required this.post, required this.themeColor});

  @override
  State<_PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<_PostDetailScreen> {
  final _commentCtrl = TextEditingController();

  Future<List<Map<String, dynamic>>> _fetchComments() =>
      SupabaseRepository().getCommentsWithUser(widget.post['id']);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(child: FutureBuilder(future: _fetchComments(), builder: (context, snapshot) {
            // ... 댓글 리스트 빌더 ...
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: widget.themeColor));
            // ...
            return ListView.separated(
              // ...
                itemBuilder: (context, index) {
                  // ...
                  return Container(
                    // ...
                      child: Row(children: [
                        // 댓글 아이콘 색상 적용
                        Icon(Icons.person, size: 16, color: widget.themeColor),
                        // ...
                      ])
                  );
                }
            );
          })),

          // 하단 댓글 입력창
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            color: const Color(0xFF0F0F0F),
            child: Row(
              children: [
                Expanded(child: TextField(
                  controller: _commentCtrl,
                  cursorColor: widget.themeColor, // 커서 색상
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true, fillColor: const Color(0xFF222222),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: widget.themeColor.withOpacity(0.5))),
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
                  icon: Icon(Icons.send_rounded, color: widget.themeColor), // 전송 버튼 색상
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}