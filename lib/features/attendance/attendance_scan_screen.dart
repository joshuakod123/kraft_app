import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 햅틱(진동)용
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

// [중요] Repository와 오버레이 위젯 import 확인해주세요.
import '../../core/data/supabase_repository.dart';
import 'widgets/scanner_overlay.dart';

class AttendanceScanScreen extends StatefulWidget {
  const AttendanceScanScreen({super.key});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  bool _isProcessing = false; // 중복 스캔 방지용 플래그
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  // QR 코드가 인식되었을 때 실행되는 함수
  void _handleBarcode(BarcodeCapture capture) async {
    // 1. 이미 처리 중이거나, QR 데이터가 없으면 무시
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    final qrData = barcodes.first.rawValue!;

    // 2. 처리 시작 (중복 호출 방지)
    setState(() {
      _isProcessing = true;
    });

    // 인식 성공 햅틱 피드백 (틱!)
    HapticFeedback.mediumImpact();

    try {
      // 3. SupabaseRepository를 통해 DB에 출석 기록 저장
      await SupabaseRepository().markAttendance(qrData);

      if (!mounted) return;

      // 4. 성공 다이얼로그 표시
      await showDialog(
        context: context,
        barrierDismissible: false, // 바깥 터치로 닫기 방지
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 64),
              const SizedBox(height: 16),
              const Text(
                '출석 완료!',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '세션 ID: $qrData',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
                context.pop(); // 스캔 화면 닫고 홈으로 이동
              },
              child: const Text('확인', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

    } catch (e) {
      // 5. 실패 시 (중복 출석 or 네트워크 에러)
      if (!mounted) return;

      // 에러 메시지 정리 (Exception: 제거)
      final errorMessage = e.toString().replaceAll('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // 실패했으므로 다시 스캔할 수 있도록 플래그 해제 (약간의 딜레이 후)
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 스캔 영역 크기 (화면의 70%)
    final scanSize = MediaQuery.of(context).size.width * 0.7;
    final scanWindow = Rect.fromCenter(
      center: Offset(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      ),
      width: scanSize,
      height: scanSize,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('QR 출석 체크', style: TextStyle(color: Colors.white)),
        actions: [
          // [수정 1] 플래시 버튼 로직 변경 (v6 대응)
          // ValueListenableBuilder 대상을 _cameraController 자체로 변경
          ValueListenableBuilder(
            valueListenable: _cameraController,
            builder: (context, state, child) {
              // state.torchState로 접근해야 함
              final isFlashOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(
                  isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: isFlashOn ? Colors.yellowAccent : Colors.white,
                ),
                onPressed: () => _cameraController.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 카메라 뷰
          MobileScanner(
            controller: _cameraController,
            scanWindow: scanWindow,
            onDetect: _handleBarcode,
            // [수정 2] errorBuilder 파라미터 변경 (3개 -> 2개)
            errorBuilder: (context, error) {
              return Center(
                child: Text(
                  '카메라 오류: ${error.errorCode}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),

          // 2. 스캐너 오버레이 (구멍 뚫린 검은 배경)
          ScannerOverlay(scanWindow: scanWindow),

          // 3. 하단 안내 문구
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'QR 코드를 사각형 안에 맞춰주세요',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                if (_isProcessing) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Colors.white),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}