import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  final Rect scanWindow;
  final double borderRadius;

  const ScannerOverlay({
    super.key,
    required this.scanWindow,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ScannerOverlayPainter(scanWindow, borderRadius),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;

  ScannerOverlayPainter(this.scanWindow, this.borderRadius);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanWindow,
          Radius.circular(borderRadius),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6) // 반투명 배경 (집중 효과)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut; // 구멍 뚫기

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    // 1. 반투명 배경 그리기
    canvas.drawPath(backgroundWithCutout, Paint()..color = Colors.black54);

    // 2. 테두리(Border) 그리기
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, Radius.circular(borderRadius)),
      borderPaint,
    );

    // (선택 사항) 모서리 포인트 장식 등을 여기에 추가할 수 있습니다.
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}