import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

import '../../core/data/supabase_repository.dart';
import 'widgets/scanner_overlay.dart';

class AttendanceScanScreen extends StatefulWidget {
  const AttendanceScanScreen({super.key});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> with WidgetsBindingObserver {
  bool _isProcessing = false;
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (mounted) {
      setState(() {
        _isPermissionGranted = status.isGranted;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      final Map<String, dynamic> data = jsonDecode(rawData);

      // QR에서 숫자 ID 추출
      final int? curriculumId = data['c'] as int?;
      final int? teamId = data['t'] as int?;

      if (curriculumId == null || teamId == null) {
        throw const FormatException();
      }

      // 출석 처리 후 서버에서 계산된 벌금 받아오기
      final int fineAmount = await SupabaseRepository().markAttendance(
        curriculumId: curriculumId,
        qrTeamId: teamId,
      );

      if (!mounted) return;

      final bool isLate = fineAmount > 0;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  isLate ? Icons.warning_rounded : Icons.check_circle_rounded,
                  color: isLate ? Colors.redAccent : Colors.greenAccent,
                  size: 64
              ),
              const SizedBox(height: 16),
              Text(
                  isLate ? '지각입니다!' : '출석 완료!',
                  style: TextStyle(
                      color: isLate ? Colors.redAccent : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold
                  )
              ),
              const SizedBox(height: 12),
              if (isLate) ...[
                Text(
                    '벌금 ${NumberFormat('#,###').format(fineAmount)}원이 부과되었습니다.',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 8),
                const Text('세션 시작 시간을 초과했습니다.', style: TextStyle(color: Colors.white54, fontSize: 13)),
              ] else ...[
                const Text('세션 출석이 확인되었습니다.', style: TextStyle(color: Colors.white70)),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
                context.pop(); // 스캔 화면 닫기
              },
              child: const Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

    } catch (e) {
      if (!mounted) return;

      String errorMessage = '스캔한 코드가 올바르지 않습니다.';
      if (e is FormatException) {
        errorMessage = '이 앱의 출석 QR코드가 아닙니다.';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("출석 실패", style: TextStyle(color: Colors.redAccent)),
          content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );

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
            errorBuilder: (context, error) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 60),
                      const SizedBox(height: 24),
                      const Text(
                        '카메라 권한이 없습니다.',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '출석 체크를 위해 설정에서\n카메라 권한을 허용해주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.settings),
                        label: const Text("설정으로 이동하여 권한 허용"),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          ScannerOverlay(scanWindow: scanWindow),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
        ],
      ),
    );
  }
}