import 'dart:convert'; // JSON Decode용
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/supabase_repository.dart';
import 'widgets/scanner_overlay.dart';

class AttendanceScanScreen extends StatefulWidget {
  const AttendanceScanScreen({super.key});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  bool _isProcessing = false;
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    final rawData = barcodes.first.rawValue!;

    setState(() {
      _isProcessing = true;
    });

    HapticFeedback.mediumImpact();

    try {
      // 1. JSON 데이터 파싱
      // 예: {"s": "1주차 세션", "t": "A팀"}
      final Map<String, dynamic> data = jsonDecode(rawData);

      final String sessionName = data['s'] ?? '알 수 없는 세션';
      final String teamName = data['t'] ?? '알 수 없는 팀';

      // 2. Repository 호출
      await SupabaseRepository().markAttendance(
        sessionName: sessionName,
        teamName: teamName,
      );

      if (!mounted) return;

      // 3. 성공 알림
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 64),
              const SizedBox(height: 16),
              const Text('출석 완료!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$sessionName / $teamName', style: const TextStyle(color: Colors.white70)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dialog 닫기
                context.pop(); // 화면 닫고 나가기
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );

    } catch (e) {
      // 4. 실패 처리
      if (!mounted) return;

      String errorMessage = '스캔한 코드가 올바르지 않습니다.';

      // JSON 파싱 에러인지 확인
      if (e is FormatException) {
        errorMessage = '이 앱의 출석 QR코드가 아닙니다.';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );

      // 잠시 후 다시 스캔 가능하도록 설정
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
    // ... UI 코드는 기존과 거의 동일합니다 ...
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
          ValueListenableBuilder(
            valueListenable: _cameraController,
            builder: (context, state, child) {
              final isFlashOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                onPressed: () => _cameraController.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            scanWindow: scanWindow,
            onDetect: _handleBarcode,
          ),
          ScannerOverlay(scanWindow: scanWindow),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}