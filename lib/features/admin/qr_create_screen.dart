import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class QrCreateScreen extends StatefulWidget {
  const QrCreateScreen({super.key});

  @override
  State<QrCreateScreen> createState() => _QrCreateScreenState();
}

class _QrCreateScreenState extends State<QrCreateScreen> {
  late String _sessionId;
  late String _displayDate;

  @override
  void initState() {
    super.initState();
    _refreshSession();
  }

  void _refreshSession() {
    final now = DateTime.now();
    // 세션 ID: DB에 저장될 값 (예: session_2024-01-01)
    _sessionId = 'session_${DateFormat('yyyy-MM-dd').format(now)}';
    // 화면 표시용 날짜
    _displayDate = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('출석 QR 생성')),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. 상단 안내 및 날짜
            const Text(
              '오늘의 출석 QR',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _displayDate,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // 2. QR 카드 (디자인 요소)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: _sessionId,
                    version: QrVersions.auto,
                    size: 240.0,
                    // 다크모드 배경에서도 QR은 흰 바탕에 검은색이 가장 잘 읽힘
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '회원들이 이 코드를 스캔하면\n자동으로 출석 처리됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 3. 하단 액션 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // 출석 명단 화면으로 이동
                    context.push('/attendance_list');
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text('출석 명단 보기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                // 필요시 강제 갱신 버튼 추가 가능
                // OutlinedButton.icon(...)
              ],
            ),
          ],
        ),
      ),
    );
  }
}