import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BulletController extends PositionComponent {
  final Vector2 direction;
  final double speed;
  final bool isEnemy; // لتمييز من أطلق الرصاصة
  bool alive = true;

  final Paint bulletPaint;
  final Paint glowPaint;

  BulletController({
    required super.position,
    required this.direction,
    this.speed = 520,
    this.isEnemy = false, // افتراضي أنها رصاصة اللاعب
  })  : bulletPaint = Paint()..color = isEnemy ? Colors.redAccent : Colors.amberAccent,
        glowPaint = Paint()..color = Colors.white.withOpacity(0.35),
        super(
          size: const Vector2(10, 6),
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
