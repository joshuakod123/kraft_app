import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';

// 아카이브 데이터 프로바이더
final myArchiveProvider = FutureProvider.autoDispose((ref) async {
  return await SupabaseRepository().fetchMyArchives();
});

// [유틸] 로컬 파일 경로 찾기
Future<File?> getLocalFile(String fileName) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    if (await file.exists()) return file;
    return null;
  } catch (e) {
    return null;
  }
}

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivesAsync = ref.watch(myArchiveProvider);
    final dept = ref.watch(currentDeptProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(myArchiveProvider),
        color: dept.color,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. 헤더 영역
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'MY ARCHIVE',
                  style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [dept.color.withOpacity(0.2), Colors.black],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => _UploadDialog(pointColor: dept.color),
                    );
                  },
                ),
                const SizedBox(width: 12),
              ],
            ),

            // 2. 리스트 영역
            archivesAsync.when(
              data: (archives) {
                if (archives.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_rounded, color: Colors.white.withOpacity(0.3), size: 64),
                          const SizedBox(height: 16),
                          const Text("저장된 파일이 없습니다.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final item = archives[index];
                        return _LocalArchiveCard(item: item, themeColor: dept.color);
                      },
                      childCount: archives.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => SliverFillRemaining(
                child: Center(child: Text('오류: $err', style: const TextStyle(color: Colors.red))),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }
}

// [개별 카드 위젯 - 삭제 기능 포함]
class _LocalArchiveCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final Color themeColor;

  const _LocalArchiveCard({required this.item, required this.themeColor});

  @override
  ConsumerState<_LocalArchiveCard> createState() => _LocalArchiveCardState();
}

class _LocalArchiveCardState extends ConsumerState<_LocalArchiveCard> {
  File? _localFile;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkFile();
  }

  Future<void> _checkFile() async {
    final fileName = widget.item['file_path'];
    if (fileName != null) {
      final file = await getLocalFile(fileName);
      if (mounted) {
        setState(() {
          _localFile = file;
          _isChecking = false;
        });
      }
    } else {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  // 파일 열기
  Future<void> _openFile() async {
    if (_localFile != null) {
      try {
        await OpenFile.open(_localFile!.path);
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("파일을 열 수 없습니다.")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("파일을 찾을 수 없습니다.")));
    }
  }

  // [핵심] 삭제 로직
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("파일 삭제", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("정말 삭제하시겠습니까?\n복구할 수 없습니다.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("삭제", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseRepository().deleteArchive(widget.item['id'], widget.item['file_path']);
        // 목록 새로고침
        ref.invalidate(myArchiveProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("삭제 실패: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = (widget.item['file_type'] ?? '').toString().toLowerCase();

    IconData fileIcon = Icons.insert_drive_file_rounded;
    if (['jpg', 'png', 'jpeg'].contains(type)) fileIcon = Icons.image_rounded;
    else if (['pdf'].contains(type)) fileIcon = Icons.picture_as_pdf_rounded;
    else if (['mp3', 'wav', 'm4a'].contains(type)) fileIcon = Icons.audiotrack_rounded;
    else if (['doc', 'docx'].contains(type)) fileIcon = Icons.description_rounded;

    return GestureDetector(
      onTap: _openFile,
      child: GlassContainer.clearGlass(
        height: double.infinity,
        width: double.infinity,
        borderRadius: BorderRadius.circular(20),
        borderWidth: 1.0,
        borderColor: Colors.white.withOpacity(0.1),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      image: (_localFile != null && ['jpg', 'png', 'jpeg'].contains(type))
                          ? DecorationImage(image: FileImage(_localFile!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: Center(
                      child: _isChecking
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : (_localFile != null && ['jpg', 'png', 'jpeg'].contains(type))
                          ? null
                          : Icon(
                        _localFile == null ? Icons.broken_image_rounded : fileIcon,
                        color: _localFile == null ? Colors.redAccent : widget.themeColor.withOpacity(0.8),
                        size: 48,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.item['title'] ?? 'Untitled',
                          style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _localFile == null ? '파일 없음' : (widget.item['description'] ?? ''),
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // [추가됨] 우측 상단 삭제 버튼
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _delete,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: Colors.white70, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// [업로드 다이얼로그]
class _UploadDialog extends ConsumerStatefulWidget {
  final Color pointColor;
  const _UploadDialog({required this.pointColor});

  @override
  ConsumerState<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends ConsumerState<_UploadDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  File? _file;
  String? _fileName;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp3', 'jpg', 'png', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _file = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty || _file == null) {
      _showMsgDialog("입력 오류", "제목과 파일을 모두 선택해주세요.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseRepository().saveArchiveLocally(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        file: _file!,
        fileName: _fileName!,
      );

      ref.invalidate(myArchiveProvider); // 새로고침

      if (!mounted) return;
      Navigator.pop(context);
      _showMsgDialog("저장 성공", "파일이 안전하게 저장되었습니다.");

    } catch (e) {
      if(mounted) _showMsgDialog("저장 실패", e.toString(), isError: true);
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showMsgDialog(String title, String content, {bool isError = false}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: isError ? Colors.redAccent : widget.pointColor,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(content, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text("확인"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Add to Archive", style: TextStyle(color: widget.pointColor, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                )
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Title", filled: true, fillColor: Colors.black38, border: InputBorder.none),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Description", filled: true, fillColor: Colors.black38, border: InputBorder.none),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.attach_file, color: _file != null ? widget.pointColor : Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_fileName ?? "Select File", style: const TextStyle(color: Colors.grey)))
                ]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: widget.pointColor, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save"),
              ),
            )
          ],
        ),
      ),
    );
  }
}