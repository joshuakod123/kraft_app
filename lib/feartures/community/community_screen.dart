import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glass_kit/glass_kit.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';
import 'package:intl/intl.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _contentCtrl = TextEditingController();
  String _selectedCategory = 'FREE'; // FREE, REVIEW, HOMEWORK

  void _showWriteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text("New Post", style: GoogleFonts.chakraPetch(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: const Color(0xFF333333),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(filled: true, fillColor: Colors.black54),
              items: ['FREE', 'REVIEW', 'HOMEWORK'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentCtrl,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: "Share your thoughts...",
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.black54
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_contentCtrl.text.isNotEmpty) {
                await SupabaseRepository().addCommunityPost(_contentCtrl.text, _selectedCategory);
                _contentCtrl.clear();
                if(mounted) Navigator.pop(context);
                setState(() {}); // 리스트 갱신
              }
            },
            child: const Text("Post"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dept = ref.watch(currentDeptProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("COMMUNITY", style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.edit_square), onPressed: _showWriteDialog)
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseRepository().getCommunityPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final posts = snapshot.data!;
          if (posts.isEmpty) return const Center(child: Text("No posts yet. Be the first!", style: TextStyle(color: Colors.grey)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final user = post['user'] ?? {};
              final date = DateTime.parse(post['created_at']).toLocal();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: GlassContainer.clearGlass(
                  height: 140,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(16),
                  borderColor: Colors.white10,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: 14, backgroundColor: dept.color.withOpacity(0.5), child: Text(user['name']?[0] ?? '?', style: const TextStyle(fontSize: 12, color: Colors.white))),
                              const SizedBox(width: 8),
                              Text(user['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: dept.color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: Text(post['category'] ?? 'FREE', style: TextStyle(color: dept.color, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: Text(post['content'], style: const TextStyle(color: Colors.white70), maxLines: 3, overflow: TextOverflow.ellipsis)),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(DateFormat('MM/dd HH:mm').format(date), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}