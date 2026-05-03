import 'package:flutter/material.dart';

class MazePlatform {
  final double yPercent; // 0.0 - 1.0 (position from top)
  final double startXPercent; // 0.0 - 1.0
  final double endXPercent; // 0.0 - 1.0
  final double gapStartPercent; // gap/hole position start
  final double gapEndPercent; // gap/hole position end

  MazePlatform({
    required this.yPercent,
    required this.startXPercent,
    required this.endXPercent,
    required this.gapStartPercent,
    required this.gapEndPercent,
  });

  // Returns two rects representing the platform (split by the gap)
  List<Rect> getRects(Size size) {
    final y = yPercent * size.height;
    final height = 14.0;
    return [
      Rect.fromLTWH(
        startXPercent * size.width,
        y,
        (gapStartPercent - startXPercent) * size.width,
        height,
      ),
      Rect.fromLTWH(
        gapEndPercent * size.width,
        y,
        (endXPercent - gapEndPercent) * size.width,
        height,
      ),
    ];
  }

  bool collidesWithCar(Rect carRect, Size size) {
    final rects = getRects(size);
    for (final rect in rects) {
      if (rect.overlaps(carRect)) return true;
    }
    return false;
  }

  bool isInGap(double carX, double carWidth, Size size) {
    final gapLeft = gapStartPercent * size.width;
    final gapRight = gapEndPercent * size.width;
    return carX >= gapLeft && (carX + carWidth) <= gapRight;
  }
}

// Predefined maze levels
List<MazePlatform> generateMaze() {
  return [
    MazePlatform(
      yPercent: 0.18,
      startXPercent: 0.0,
      endXPercent: 1.0,
      gapStartPercent: 0.55,
      gapEndPercent: 0.80,
    ),
    MazePlatform(
      yPercent: 0.32,
      startXPercent: 0.0,
      endXPercent: 1.0,
      gapStartPercent: 0.10,
      gapEndPercent: 0.38,
    ),
    MazePlatform(
      yPercent: 0.46,
      startXPercent: 0.0,
      endXPercent: 1.0,
      gapStartPercent: 0.62,
      gapEndPercent: 0.90,
    ),
    MazePlatform(
      yPercent: 0.60,
      startXPercent: 0.0,
      endXPercent: 1.0,
      gapStartPercent: 0.25,
      gapEndPercent: 0.55,
    ),
    MazePlatform(
      yPercent: 0.74,
      startXPercent: 0.0,
      endXPercent: 1.0,
      gapStartPercent: 0.50,
      gapEndPercent: 0.78,
    ),
  ];
}
