import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MagazineUploadScreen extends ConsumerStatefulWidget {
  const MagazineUploadScreen({super.key});

  @override
  ConsumerState<MagazineUploadScreen> createState() => _MagazineUploadScreenState();
}

class _MagazineUploadScreenState extends ConsumerState<MagazineUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _urlController = TextEditingController(); // 노션 링크나 PDF URL

  File? _imageFile;
  bool _isLoading = false;

  // 이미지 선택
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 업로드 로직
  Future<void> _uploadMagazine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('커버 이미지를 선택해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final fileName = 'mag_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 1. Storage에 이미지 업로드 (Bucket 이름: 'magazine_covers'라고 가정)
      // [주의] Supabase Storage에 'magazine_covers' 버킷을 Public으로 생성해야 합니다.
      await supabase.storage.from('magazine_covers').upload(
        fileName,
        _imageFile!,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      final imageUrl = supabase.storage.from('magazine_covers').getPublicUrl(fileName);

      // 2. DB Insert
      await supabase.from('magazines').insert({
        'title': _titleController.text,
        'subtitle': _subtitleController.text,
        'cover_image_url': imageUrl,
        'content_url': _urlController.text,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('매거진 발행 성공!')));
        context.pop(); // 목록으로 복귀
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text("매거진 발행"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 선택 영역
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                    image: _imageFile != null
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageFile == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("커버 이미지 선택", style: TextStyle(color: Colors.grey)),
                    ],
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField("제목", _titleController),
              const SizedBox(height: 16),
              _buildTextField("부제목", _subtitleController),
              const SizedBox(height: 16),
              _buildTextField("기사 URL (Notion/Blog 등)", _urlController),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _uploadMagazine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("발행하기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          validator: (value) => value!.isEmpty ? "필수 입력값입니다." : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}