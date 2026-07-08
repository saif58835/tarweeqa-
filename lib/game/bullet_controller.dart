import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BulletController extends PositionComponent {
  final Vector2 direction;
  final double speed;
  bool alive = true;

  final Paint bulletPaint = Paint()..color = Colors.amberAccent;
  final Paint glowPaint = Paint()..color = Colors.white.withOpacity(0.35);

  BulletController({
    required super.position,
    required this.direction,
    this.speed = 520,
  }) : super(
          size: Vector2(16, 8),
          anchor: Anchor.center,
        );

  void updateBullet(double dt) {
    position += direction * speed * dt;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      bulletPaint,
    );

    canvas.drawCircle(const Offset(0, 0), 3.5, glowPaint);
  }
}
