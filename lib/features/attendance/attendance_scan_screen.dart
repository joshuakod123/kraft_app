import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/data/supabase_repository.dart';

class AttendanceScanScreen extends StatefulWidget {
  const AttendanceScanScreen({super.key});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  final SupabaseRepository _repo = SupabaseRepository();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);

        final success = await _repo.markAttendance(barcode.rawValue!);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ 출석 체크 완료!'), backgroundColor: Colors.green),
            );
            Navigator.pop(context); // 홈으로 복귀
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ 유효하지 않은 QR 코드입니다.'), backgroundColor: Colors.red),
            );
            setState(() => _isProcessing = false); // 재시도 가능하게
          }
        }
        break; // 하나만 처리
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR SCAN")),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}