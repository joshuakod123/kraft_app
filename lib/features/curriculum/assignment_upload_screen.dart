import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart'; // 추가 필요
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
          const SnackBar(content: Text('✅ Mission Completed! (+20 PT)'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload Cancelled or Failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('WEEK ${widget.item.week} MISSION', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item.title,
              style: GoogleFonts.chakraPetch(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              widget.item.description,
              style: const TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 40),

            GestureDetector(
              onTap: _isUploading ? null : _pickAndUpload,
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: themeColor.withValues(alpha: 0.5), width: 2),
                  borderRadius: BorderRadius.circular(24),
                  color: themeColor.withValues(alpha: 0.05),
                ),
                child: _isUploading
                    ? Center(child: CircularProgressIndicator(color: themeColor))
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_rounded, size: 64, color: themeColor),
                    const SizedBox(height: 16),
                    Text('Tap to Upload File', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('PDF, ZIP, JPG supported', style: TextStyle(color: Colors.grey, fontSize: 12)),
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