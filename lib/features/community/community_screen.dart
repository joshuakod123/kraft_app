import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:glass_kit/glass_kit.dart'; // GlassContainer 사용
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  // 실시간 스트림 대신 Join 쿼리를 위해 Future 사용 (간단한 구현을 위해 RefreshIndicator 사용 권장)
  // 하지만 여기선 UX를 위해 StreamBuilder 구조를 유지하되, 유저 정보는 로컬 로직으로 처리하거나
  // Supabase의 View 기능을 쓰면 좋지만, 코드가 복잡해지므로
  // 여기서는 'FutureBuilder'로 목록을 불러오고 'RefreshIndicator'를 붙이는 방식을 택하겠습니다.

  Future<List<Map<String, dynamic>>> _fetchPosts() => SupabaseRepository().getCommunityPostsWithUser();

  void _showWriteDialog() {
    final contentCtrl = TextEditingController();
    String selectedCategory = 'General';
    final categories = ['General', 'Question', 'Notice', 'Free'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text('새 글 작성', style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: Colors.grey[900],
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (val) => setState(() => selectedCategory = val!),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: '내용을 입력하세요...',
                    hintStyle: TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.black38,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () async {
                  if (contentCtrl.text.trim().isNotEmpty) {
                    await SupabaseRepository().addCommunityPost(contentCtrl.text.trim(), selectedCategory);
                    if (mounted) {
                      Navigator.pop(context);
                      // 리스트 새로고침 트리거 (setState로 Future 재실행)
                      this.setState(() {});
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                child: const Text('등록'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('COMMUNITY', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.cyanAccent, size: 30),
            onPressed: _showWriteDialog,
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text("첫 번째 글을 남겨보세요!", style: GoogleFonts.inter(color: Colors.white54)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            color: Colors.cyanAccent,
            backgroundColor: Colors.grey[900],
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _PostCard(post: posts[index], onRefresh: () => setState(() {}));
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
  final VoidCallback onRefresh;

  const _PostCard({required this.post, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isManager = ref.watch(isManagerProvider);
    final date = DateTime.parse(post['created_at']).toLocal();
    final formattedDate = DateFormat('MM.dd HH:mm').format(date);
    final userName = post['users']?['name'] ?? 'Unknown'; // Join된 데이터

    return GestureDetector(
      onTap: () {
        // 상세 페이지(댓글창)로 이동
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => _PostDetailScreen(post: post)),
        );
      },
      child: GlassContainer.clearGlass(
        height: 140, // 내용 길이에 따라 조절 필요하면 Container로 변경
        width: double.infinity,
        borderRadius: BorderRadius.circular(16),
        borderWidth: 1.0,
        borderColor: Colors.white12,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        post['category'] ?? 'General',
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Row(
                  children: [
                    Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    // [임원진 기능] 삭제 버튼
                    if (isManager) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: const Text("게시글 삭제", style: TextStyle(color: Colors.white)),
                              content: const Text("정말 삭제하시겠습니까? (관리자 권한)", style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await SupabaseRepository().deleteCommunityPost(post['id']);
                            onRefresh();
                          }
                        },
                        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      ),
                    ]
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                post['content'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text("댓글 달기", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// [상세 페이지 & 댓글]
class _PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  const _PostDetailScreen({required this.post});

  @override
  State<_PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<_PostDetailScreen> {
  final _commentCtrl = TextEditingController();

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
          // 1. 게시글 본문 영역
          Container(
            padding: const EdgeInsets.all(24),
            color: const Color(0xFF1E1E1E),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(userName, style: GoogleFonts.chakraPetch(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  widget.post['content'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // 2. 댓글 리스트 영역
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchComments(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data!;

                if (comments.isEmpty) {
                  return const Center(child: Text("아직 댓글이 없습니다.", style: TextStyle(color: Colors.white30)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final cDate = DateFormat('MM.dd HH:mm').format(DateTime.parse(comment['created_at']).toLocal());
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(radius: 16, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 16, color: Colors.white)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(comment['users']?['name'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(width: 8),
                                  Text(cDate, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(comment['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        )
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 3. 댓글 입력창 (하단 고정)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '댓글 작성...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.black,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    if (_commentCtrl.text.trim().isNotEmpty) {
                      await SupabaseRepository().addComment(widget.post['id'], _commentCtrl.text.trim());
                      _commentCtrl.clear();
                      setState(() {}); // 댓글 새로고침
                    }
                  },
                  icon: const Icon(Icons.send, color: Colors.cyanAccent),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}