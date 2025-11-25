import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCreateScreen extends StatelessWidget {
  const QrCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String qrData = "KRAFT_ATTENDANCE_${DateTime.now().toIso8601String()}";
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text('ATTENDANCE QR')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "스캔하여 출석 체크하세요",
              style: TextStyle(
                color: themeColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}