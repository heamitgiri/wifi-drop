import 'dart:math';
import 'package:flutter/material.dart';

class RadarPainter extends CustomPainter {
  final double pulseAnimation;

  RadarPainter({this.pulseAnimation = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2 * 0.95;

    // 1. Subtle inner circular fill (3rd ring area)
    final fillPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * 0.58, fillPaint);

    // 2. 4 Fine concentric rings
    final ringPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final ringFractions = [0.35, 0.58, 0.78, 0.98];
    for (final fraction in ringFractions) {
      canvas.drawCircle(center, maxRadius * fraction, ringPaint);
    }

    // 3. Optional soft pulsing outer ring
    if (pulseAnimation > 0.0) {
      final pulseRadius = maxRadius * (0.35 + (0.63 * pulseAnimation));
      final pulseOpacity = (1.0 - pulseAnimation) * 0.25;
      final pulsePaint = Paint()
        ..color = const Color(0xFF93DBFF).withOpacity(pulseOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, pulseRadius, pulsePaint);
    }

    // 4. Center self-device halo (soft cyan rings around center)
    final outerHaloPaint = Paint()
      ..color = const Color(0xFF93DBFF).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    canvas.drawCircle(center, 34.0, outerHaloPaint);

    final innerHaloPaint = Paint()
      ..color = const Color(0xFF0588F7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 30.0, innerHaloPaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.pulseAnimation != pulseAnimation;
  }
}
