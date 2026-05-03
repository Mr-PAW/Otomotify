import 'package:flutter/material.dart';
import '../models/maze_model.dart';

class MazePainter extends CustomPainter {
  final List<MazePlatform> platforms;
  final double animOffset;

  MazePainter({required this.platforms, this.animOffset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    // Background grid lines (subtle)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw finish line at bottom
    final finishPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 3;
    final finishDashPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3;

    // Checkered finish
    final finishY = size.height - 20;
    for (int i = 0; i < (size.width / 20).ceil(); i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * 20.0, finishY, 10, 10),
        (i % 2 == 0) ? finishPaint : finishDashPaint,
      );
    }

    // Draw platforms
    for (int i = 0; i < platforms.length; i++) {
      final platform = platforms[i];
      final rects = platform.getRects(size);
      final platformColor = Color.lerp(
        const Color(0xFF7B1FA2),
        const Color(0xFF4A148C),
        i / platforms.length,
      )!;

      for (final rect in rects) {
        // Shadow
        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.translate(0, 3),
            const Radius.circular(4),
          ),
          shadowPaint,
        );

        // Platform body
        final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            platformColor.withOpacity(0.95),
            platformColor.withOpacity(0.7),
          ],
        );
        final paint = Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );

        // Top highlight
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.25)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(rect.left, rect.top, rect.width, 3),
            const Radius.circular(2),
          ),
          highlightPaint,
        );

        // Side edge light
        final edgePaint = Paint()
          ..color = const Color(0xFFCE93D8).withOpacity(0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          edgePaint,
        );
      }

      // Gap/hole indicators - glowing arrows pointing down
      final gapCenterX =
          (platform.gapStartPercent + platform.gapEndPercent) / 2 * size.width;
      final gapY = platform.yPercent * size.height;
      final arrowPaint = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Down arrows in gap
      for (int a = -1; a <= 1; a++) {
        final ax = gapCenterX + a * 12;
        final arrowPath = Path()
          ..moveTo(ax, gapY - 6)
          ..lineTo(ax, gapY + 6)
          ..moveTo(ax - 4, gapY + 1)
          ..lineTo(ax, gapY + 6)
          ..lineTo(ax + 4, gapY + 1);
        canvas.drawPath(arrowPath, arrowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MazePainter oldDelegate) =>
      oldDelegate.animOffset != animOffset;
}
