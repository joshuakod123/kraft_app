import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/supabase_repository.dart';
import 'curriculum_provider.dart';

class AssignmentUploadScreen extends ConsumerStatefulWidget {
  final CurriculumItem item;

  const AssignmentUploadScreen({super.key, required this.item});

  @override
  ConsumerState<AssignmentUploadScreen> createState() => _AssignmentUploadScreenState();
}

class _AssignmentUploadScreenState extends ConsumerState<AssignmentUploadScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    setState(() => _isUploading = true);

    final success = await SupabaseRepository().uploadAssignment(widget.item.id);

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 과제 제출 완료! (+20 PT)')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ 업로드 실패 또는 취소됨')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: Text('WEEK ${widget.item.week} SUBMISSION')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _isUploading ? null : _pickAndUpload,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[800]!),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                child: _isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 48, color: themeColor),
                    const SizedBox(height: 12),
                    const Text('Tap to upload PDF or ZIP'),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}