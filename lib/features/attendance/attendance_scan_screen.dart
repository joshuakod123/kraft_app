import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/data/supabase_repository.dart';

class AttendanceScanScreen extends StatefulWidget {
  const AttendanceScanScreen({super.key});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        final sessionId = barcode.rawValue!;

        final success = await SupabaseRepository().markAttendance(sessionId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? "✅ 출석 완료!" : "❌ 출석 실패 (이미 완료했거나 오류)"),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
          if (success) Navigator.pop(context); // 성공 시 화면 닫기
          else setState(() => _isProcessing = false); // 실패 시 다시 스캔 가능하게
        }
        break; // 하나만 인식하고 종료
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code"), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}