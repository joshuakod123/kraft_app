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
  String _selectedCategory = 'FREE';

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
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Message...", filled: true, fillColor: Colors.black54),
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
                setState(() {});
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
        actions: [IconButton(icon: const Icon(Icons.edit_square), onPressed: _showWriteDialog)],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseRepository().getCommunityPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final posts = snapshot.data!;
          if (posts.isEmpty) return const Center(child: Text("No posts yet.", style: TextStyle(color: Colors.grey)));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final user = post['user'] ?? {};
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: GlassContainer.clearGlass(
                  height: 120, width: double.infinity, borderRadius: BorderRadius.circular(16), borderColor: Colors.white10, padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(user['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(post['category'] ?? 'FREE', style: TextStyle(color: dept.color, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(post['content'], style: const TextStyle(color: Colors.white70), maxLines: 3),
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