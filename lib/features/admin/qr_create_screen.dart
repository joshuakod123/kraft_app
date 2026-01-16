import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../core/data/supabase_repository.dart';

class QrCreateScreen extends ConsumerStatefulWidget {
  const QrCreateScreen({super.key});

  @override
  ConsumerState<QrCreateScreen> createState() => _QrCreateScreenState();
}

class _QrCreateScreenState extends ConsumerState<QrCreateScreen> {
  final SupabaseRepository _repository = SupabaseRepository();

  List<String> _sessionOptions = [];
  String? _selectedSession;

  String? _generatedQrData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSessionOptions();
  }

  // [수정 2] 세션 로딩 시 내 팀 ID 전달
  Future<void> _loadSessionOptions() async {
    final myDept = ref.read(currentDeptProvider);
    final options = await _repository.getSessionOptions(myDept.id); // teamId 전달!

    if (mounted) {
      setState(() {
        _sessionOptions = options;
        if (options.isNotEmpty) {
          _selectedSession = options.first;
        }
      });
    }
  }

  void _generateQrCode() {
    if (_selectedSession == null) return;

    final myDept = ref.read(currentDeptProvider);

    // QR 데이터 JSON 생성
    // s: 세션 이름, t: 팀 이름 (출석 처리 시 검증용)
    final Map<String, dynamic> qrData = {
      's': _selectedSession,
      't': myDept.name,
      'ts': DateTime.now().millisecondsSinceEpoch, // 타임스탬프 (옵션)
    };

    setState(() {
      _generatedQrData = jsonEncode(qrData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final myDept = ref.watch(currentDeptProvider);
    final themeColor = myDept.color;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("QR 생성 (출석체크)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeColor.withOpacity(0.2),
              const Color(0xFF121212),
              const Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // 1. 세션 선택 카드
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("출석 세션 선택", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      if (_sessionOptions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text("등록된 공식 세션이 없습니다.\n캘린더에서 먼저 등록해주세요.", style: TextStyle(color: Colors.white54)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSession,
                              dropdownColor: const Color(0xFF2C2C2C),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down, color: themeColor),
                              items: _sessionOptions.map((e) {
                                return DropdownMenuItem(value: e, child: Text(e));
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedSession = val),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 2. 생성 버튼
                ElevatedButton.icon(
                  onPressed: _sessionOptions.isEmpty ? null : _generateQrCode,
                  icon: const Icon(Icons.qr_code_rounded),
                  label: const Text("QR 코드 생성하기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    disabledBackgroundColor: Colors.grey[800],
                    disabledForegroundColor: Colors.white38,
                  ),
                ),

                const SizedBox(height: 40),

                // 3. QR 코드 결과 영역
                Expanded(
                  child: Center(
                    child: _generatedQrData != null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: themeColor.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)
                              ]
                          ),
                          child: QrImageView(
                            data: _generatedQrData!,
                            version: QrVersions.auto,
                            size: 240.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "$_selectedSession",
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "팀원들에게 이 QR을 보여주세요.",
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      ],
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 80, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Text("세션을 선택하고 생성 버튼을 눌러주세요", style: TextStyle(color: Colors.white.withOpacity(0.3))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}