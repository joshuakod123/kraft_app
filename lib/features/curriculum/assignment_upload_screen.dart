import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'curriculum_provider.dart';

class AssignmentUploadScreen extends ConsumerWidget {
  final CurriculumItem item;

  const AssignmentUploadScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: Text('WEEK ${item.week} SUBMISSION')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 파일 업로드 영역 (더미 UI)
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[800]!),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.05),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 48, color: themeColor),
                  const SizedBox(height: 12),
                  const Text('Tap to upload PDF or ZIP'),
                ],
              ),
            ),

            const Spacer(),

            // 제출 버튼
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('과제 제출이 완료되었습니다! (+20 PT)')),
                );
                Navigator.pop(context);
              },
              child: const Text('SUBMIT ASSIGNMENT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}