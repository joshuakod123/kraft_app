import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/supabase_repository.dart';
// [필수] Department Enum 및 색상을 가져오기 위해 import
import '../../core/constants/department_enum.dart';

class QrCreateScreen extends StatefulWidget {
  const QrCreateScreen({super.key});

  @override
  State<QrCreateScreen> createState() => _QrCreateScreenState();
}

class _QrCreateScreenState extends State<QrCreateScreen> {
  // 세션 관련 변수
  List<String> _sessionOptions = [];
  bool _isLoading = true;
  String? _selectedSession;

  // [수정] 팀 선택 변수 (String -> Department Enum)
  // 기본값은 첫 번째 부서로 설정 (null 방지)
  Department _selectedTeam = Department.values.first;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    final sessions = await SupabaseRepository().getSessionOptions();

    if (mounted) {
      setState(() {
        _sessionOptions = sessions;
        if (_sessionOptions.isNotEmpty) {
          _selectedSession = _sessionOptions.first;
        } else {
          _selectedSession = null;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // QR 데이터 생성 (JSON)
    // t: 팀 이름 (Enum의 name 속성 사용, 예: "business", "aNr")
    final String? qrData = _selectedSession != null
        ? jsonEncode({
      's': _selectedSession,
      't': _selectedTeam.name,
    })
        : null;

    final String today = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(DateTime.now());

    // 현재 선택된 팀의 색상 가져오기
    final Color currentTeamColor = _selectedTeam.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('출석 QR 생성'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchSessions();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('오늘의 출석 정보 선택', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Text(today, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 30),

            // 1. 세션(주차) 선택
            if (_sessionOptions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Expanded(child: Text('등록된 공식 세션이 없습니다.\n캘린더에서 세션을 추가해주세요.', style: TextStyle(fontSize: 12))),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '세션(주차) 선택',
                  border: OutlineInputBorder(),
                  helperText: '캘린더에 등록된 공식 세션 목록입니다.',
                ),
                value: _selectedSession,
                items: _sessionOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _selectedSession = val),
              ),

            const SizedBox(height: 20),

            // [수정됨] 2. 팀 선택 (Department Enum 연동 + 색상 표시)
            DropdownButtonFormField<Department>(
              decoration: InputDecoration(
                labelText: '대상 팀 선택',
                border: const OutlineInputBorder(),
                // 선택된 팀의 색상으로 테두리 포인트
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: currentTeamColor, width: 2),
                ),
              ),
              value: _selectedTeam,
              items: Department.values.map((dept) {
                return DropdownMenuItem<Department>(
                  value: dept,
                  child: Row(
                    children: [
                      // 팀 색상 원형 표시
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: dept.color, // Enum에 정의된 색상 사용
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: dept.color.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ]
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 팀 이름 (대문자로 표시)
                      Text(
                        dept.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedTeam = val);
                }
              },
            ),

            const SizedBox(height: 40),

            // 3. QR 코드 카드
            if (qrData != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: currentTeamColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                  border: Border.all(color: currentTeamColor.withOpacity(0.5), width: 1),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 220.0,
                      backgroundColor: Colors.white,
                      // QR 코드 눈(eye) 색상도 팀 컬러로 맞춤 (선택사항)
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black, // 인식률을 위해 검정 권장하지만, 원하면 currentTeamColor 가능
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentTeamColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _selectedTeam.name.toUpperCase(),
                            style: TextStyle(color: currentTeamColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_selectedSession 출석용',
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '팀원들이 이 코드를 스캔하게 해주세요.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(
                height: 200,
                child: Center(child: Text("세션을 선택하면 QR코드가 생성됩니다.")),
              ),
          ],
        ),
      ),
    );
  }
}