import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class EnemyController extends PositionComponent {
  int health = 3;
  final Paint bodyPaint = Paint()..color = const Color(0xFFFF4D6D);
  final Paint eyePaint = Paint()..color = Colors.white.withOpacity(0.75);

  EnemyController({
    required super.position,
  }) : super(
          size: Vector2(48, 48),
          anchor: Anchor.center,
        );

  void reset(Random random, Vector2 screenSize) {
    health = 3;
    position = Vector2(
      screenSize.x * 0.55 + random.nextDouble() * (screenSize.x * 0.35),
      110 + random.nextDouble() * (screenSize.y * 0.55),
    );
  }

  void follow(Vector2 target, double dt, Vector2 screenSize) {
    final direction = target - position;
    if (direction.length > 1) {
      direction.normalize();
      position += direction * 95 * dt;
    }

    position.x = position.x.clamp(24, screenSize.x - 24);
    position.y = position.y.clamp(80, screenSize.y - 24);
  }

  void hit() {
    health--;
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

    canvas.drawCircle(const Offset(-7, -4), 3.5, eyePaint);
    canvas.drawCircle(const Offset(7, -4), 3.5, eyePaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 8), width: 18, height: 5),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withOpacity(0.35),
    );
  }
}
