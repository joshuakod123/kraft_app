import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';


// [1] 게시글 목록 Provider
final communityListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  // *주의: SupabaseRepository에 getCommunityPostsWithUser() 함수가 있어야 합니다.
  return SupabaseRepository().getCommunityPostsWithUser();
});

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  // [2] 글쓰기 모달 (Glassmorphism 적용)
  void _showStylishWriteDialog(BuildContext context, WidgetRef ref, Color themeColor) {
    final contentCtrl = TextEditingController();
    String selectedCategory = 'General';
    final categories = ['General', 'Question', 'Notice', 'Free'];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Write",
      barrierColor: Colors.black.withOpacity(0.8),
      pageBuilder: (ctx, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: GlassContainer(
                  height: 500,
                  width: MediaQuery.of(context).size.width * 0.9,
                  borderRadius: BorderRadius.circular(24),
                  borderWidth: 1.5,
                  borderColor: themeColor.withOpacity(0.5),
                  blur: 15,
                  elevation: 10,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2A2A2A).withOpacity(0.6),
                      const Color(0xFF1A1A1A).withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "NEW POST",
                              style: GoogleFonts.chakraPetch(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: themeColor, blurRadius: 10),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: Colors.white54),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Category Selector
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              dropdownColor: const Color(0xFF1E1E1E),
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down, color: themeColor),
                              items: categories.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => selectedCategory = val!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Text Area
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: themeColor.withOpacity(0.3)),
                            ),
                            child: TextField(
                              controller: contentCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              maxLines: null,
                              expands: true,
                              cursorColor: themeColor,
                              decoration: const InputDecoration(
                                hintText: 'Share your creative thoughts...',
                                hintStyle: TextStyle(color: Colors.white30),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (contentCtrl.text.trim().isNotEmpty) {
                                final success = await SupabaseRepository().addCommunityPost(
                                  contentCtrl.text.trim(),
                                  selectedCategory,
                                );

                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  // 목록 새로고침
                                  ref.invalidate(communityListProvider);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor.withOpacity(0.2),
                              foregroundColor: themeColor,
                              shadowColor: themeColor.withOpacity(0.5),
                              elevation: 5,
                              side: BorderSide(color: themeColor, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              "UPLOAD SIGNAL",
                              style: GoogleFonts.chakraPetch(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  shadows: [Shadow(color: themeColor, blurRadius: 5)]
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(duration: 300.ms),
            );
          },
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) => child,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 부서 색상 (Directing -> Red 등)
    final dept = ref.watch(currentDeptProvider);
    final themeColor = dept.color;

    final postsAsync = ref.watch(communityListProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('COMMUNITY', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white, // tintColor 에러 수정됨
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => _showStylishWriteDialog(context, ref, themeColor),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: themeColor.withOpacity(0.5)),
                  boxShadow: [BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 10)],
                ),
                child: Icon(Icons.edit, color: themeColor, size: 24),
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
                  Icon(Icons.hub, size: 60, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text("NO SIGNALS YET", style: GoogleFonts.chakraPetch(color: Colors.white30, fontSize: 18)),
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
      // [수정] GlassContainer.clearGlass -> GlassContainer로 변경하여 gradient 오류 해결
      child: GlassContainer(
        height: 150,
        width: double.infinity,
        borderRadius: BorderRadius.circular(20),
        borderWidth: 1.0,
        borderColor: Colors.white.withOpacity(0.1),
        blur: 10,
        elevation: 5,
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2A2A2A).withOpacity(0.6),
            const Color(0xFF1A1A1A).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.15),
                          border: Border.all(color: themeColor.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post['category'] ?? 'General',
                          style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  ),
                  Row(
                    children: [
                      Text(formattedDate, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      if (isManager) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                title: const Text("Delete Post", style: TextStyle(color: Colors.white)),
                                content: const Text("Are you sure?", style: TextStyle(color: Colors.white70)),
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
                          child: Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.8), size: 20),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Text(
                  post['content'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white.withOpacity(0.4)),
                  const SizedBox(width: 6),
                  Text("Tap to discuss", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final Color themeColor;
  const _PostDetailScreen({required this.post, required this.themeColor});

  @override
  State<_PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<_PostDetailScreen> {
  final _commentCtrl = TextEditingController();

  // 댓글 가져오기 Future
  Future<List<Map<String, dynamic>>> _fetchComments() =>
      SupabaseRepository().getCommentsWithUser(widget.post['id']);

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.post['created_at']).toLocal();
    final formattedDate = DateFormat('yyyy.MM.dd HH:mm').format(date);
    final userName = widget.post['users']?['name'] ?? 'Unknown';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Column(
        children: [
          // 본문
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(userName, style: GoogleFonts.chakraPetch(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  widget.post['content'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
                ),
              ],
            ),
          ),

          // 댓글 리스트
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchComments(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data!;

                if (comments.isEmpty) {
                  return const Center(child: Text("Be the first to comment.", style: TextStyle(color: Colors.white30)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final cDate = DateFormat('MM.dd HH:mm').format(DateTime.parse(comment['created_at']).toLocal());
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                              radius: 14,
                              backgroundColor: widget.themeColor.withOpacity(0.2),
                              child: Icon(Icons.person, size: 16, color: widget.themeColor)
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(comment['users']?['name'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Text(cDate, style: const TextStyle(color: Colors.white30, fontSize: 10)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 댓글 입력창
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF222222),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: widget.themeColor.withOpacity(0.5))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () async {
                    if (_commentCtrl.text.trim().isNotEmpty) {
                      await SupabaseRepository().addComment(widget.post['id'], _commentCtrl.text.trim());
                      _commentCtrl.clear();
                      setState(() {});
                    }
                  },
                  icon: Icon(Icons.send_rounded, color: widget.themeColor),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}