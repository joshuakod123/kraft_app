import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class MagazineUploadScreen extends ConsumerStatefulWidget {
  const MagazineUploadScreen({super.key});

  @override
  ConsumerState<MagazineUploadScreen> createState() => _MagazineUploadScreenState();
}

class _MagazineUploadScreenState extends ConsumerState<MagazineUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _contentController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadMagazine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('커버 이미지를 선택해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // 1. 이미지 업로드 (Storage bucket 이름: magazines 가 존재해야 함)
      final fileExt = _selectedImage!.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = '$userId/$fileName';

      await supabase.storage.from('magazines').upload(filePath, _selectedImage!);
      final imageUrl = supabase.storage.from('magazines').getPublicUrl(filePath);

      // 2. DB Insert
      await supabase.from('magazines').insert({
        'title': _titleController.text,
        'subtitle': _subtitleController.text,
        'content': _contentController.text,
        'cover_image_url': imageUrl,
        'author_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        context.pop(); // 업로드 성공 후 뒤로가기
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('매거진 발행 성공!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 매거진 발행')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 커버 이미지 선택
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _selectedImage != null
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedImage == null
                      ? const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                      Text("커버 이미지 선택"),
                    ],
                  ))
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // 제목 입력
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '제목', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? '제목을 입력하세요' : null,
              ),
              const SizedBox(height: 16),

              // 부제목 입력
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(labelText: '부제목 (한 줄 요약)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // 본문 입력 (Markdown)
              TextFormField(
                controller: _contentController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: '본문 (Markdown 지원)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => value!.isEmpty ? '내용을 입력하세요' : null,
              ),
              const SizedBox(height: 24),

              // 업로드 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _uploadMagazine,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('발행하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}