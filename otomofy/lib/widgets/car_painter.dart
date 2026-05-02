import 'package:flutter/material.dart';

class CarPainter extends CustomPainter {
  final Color bodyColor;
  final Color windowColor;

  const CarPainter({
    this.bodyColor = const Color(0xFF9C27B0),
    this.windowColor = const Color(0xFF1A1A2E),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Car body
    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.6, w * 0.9, h * 0.45),
        const Radius.circular(6),
      ),
      shadowPaint,
    );

    // Main body bottom
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.5, w, h * 0.45),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Car top/cabin
    final cabinPath = Path()
      ..moveTo(w * 0.2, h * 0.5)
      ..lineTo(w * 0.15, h * 0.2)
      ..lineTo(w * 0.85, h * 0.2)
      ..lineTo(w * 0.8, h * 0.5)
      ..close();
    canvas.drawPath(cabinPath, bodyPaint);

    // Windshield
    final windowPaint = Paint()
      ..color = windowColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final windowPath = Path()
      ..moveTo(w * 0.25, h * 0.48)
      ..lineTo(w * 0.22, h * 0.25)
      ..lineTo(w * 0.78, h * 0.25)
      ..lineTo(w * 0.75, h * 0.48)
      ..close();
    canvas.drawPath(windowPath, windowPaint);

    // Window shine
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final shinePath = Path()
      ..moveTo(w * 0.26, h * 0.27)
      ..lineTo(w * 0.30, h * 0.27)
      ..lineTo(w * 0.27, h * 0.46)
      ..lineTo(w * 0.23, h * 0.46)
      ..close();
    canvas.drawPath(shinePath, shinePaint);

    // Wheels
    final wheelPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..style = PaintingStyle.fill;

    // Left wheel
    canvas.drawCircle(Offset(w * 0.22, h * 0.95), w * 0.14, wheelPaint);
    canvas.drawCircle(Offset(w * 0.22, h * 0.95), w * 0.07, rimPaint);

    // Right wheel
    canvas.drawCircle(Offset(w * 0.78, h * 0.95), w * 0.14, wheelPaint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.95), w * 0.07, rimPaint);

    // Headlights (bottom - facing down since car falls)
    final headlightPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.91, w * 0.18, h * 0.07),
        const Radius.circular(3),
      ),
      headlightPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.77, h * 0.91, w * 0.18, h * 0.07),
        const Radius.circular(3),
      ),
      headlightPaint,
    );

    // Glow on body
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.52, w * 0.9, h * 0.08),
        const Radius.circular(4),
      ),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CarPainter oldDelegate) =>
      oldDelegate.bodyColor != bodyColor;
}
