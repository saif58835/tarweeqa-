import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlayerController extends PositionComponent {
  bool left = false;
  bool right = false;
  bool up = false;
  bool down = false;
  bool fire = false;

  final Paint bodyPaint = Paint()..color = const Color(0xFF00E5FF);
  final Paint glowPaint = Paint()..color = Colors.white.withOpacity(0.25);

  PlayerController({
    required super.position,
  }) : super(
          size: Vector2(48, 48),
          anchor: Anchor.center,
        );

  void setInput(bool l, bool r, bool u, bool d, bool f) {
    left = l;
    right = r;
    up = u;
    down = d;
    fire = f;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      bodyPaint,
    );

    canvas.drawCircle(
      const Offset(0, -6),
      8,
      glowPaint,
    );

    canvas.drawCircle(
      const Offset(10, -6),
      5,
      Paint()..color = Colors.white.withOpacity(0.55),
    );
  }
}
