import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class EnemyController extends PositionComponent {
  int health = 3;
  static const double speed = 70.0; // سرعة العدو أبطأ قليلاً من اللاعب
  static const double shootCooldown = 0.8; // يطلق نار كل 0.8 ثانية
  double _timeSinceLastShot = 0.0;

  // ألوان العدو
  final Paint bodyPaint = Paint()..color = const Color(0xFFFF3B30); // أحمر
  final Paint eyePaint = Paint()..color = Colors.yellow.withOpacity(0.9);
  final Paint glowPaint = Paint()..color = Colors.red.withOpacity(0.3);

  EnemyController({
    required super.position,
  }) : super(
          size: Vector2(40, 40), // نفس حجم اللاعب
          anchor: Anchor.center,
        );

  // دالة لإعادة تعيين العدو بعد موته (تستخدمها لعبة المعركة)
  void reset(Random random, Vector2 screenSize) {
    health = 3;
    // يظهر في مكان عشوائي في الجهة المقابلة للاعب
    position = Vector2(
      screenSize.x * 0.55 + random.nextDouble() * (screenSize.x * 0.35),
      110 + random.nextDouble() * (screenSize.y - 220),
    );
  }

  // دالة متابعة اللاعب وإطلاق النار
  void follow(Vector2 target, double dt, Vector2 screenSize) {
    final direction = target - position;
    
    // التحرك نحو اللاعب
    if (direction.length > 1) {
      direction.normalize();
      position += direction * speed * dt;
    }

    // منع العدو من الخروج عن حدود الشاشة
    position.x = position.x.clamp(20, screenSize.x - 20);
    position.y = position.y.clamp(90, screenSize.y - 20);

    // **جديد: منطق إطلاق النار**
    _timeSinceLastShot += dt;
    if (_timeSinceLastShot >= shootCooldown) {
      _timeSinceLastShot = 0.0;
      // هنا سنقوم بإطلاق رصاصة من العدو (سنضيفها لاحقاً في ملف المعركة)
    }
  }

  // دالة عند إصابة العدو
  void hit() {
    health--;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // رسم جسم العدو (مربع بحواف دائرية)
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      bodyPaint,
    );

    // رسم العيون الصفراء (الشريرة)
    canvas.drawCircle(const Offset(-8, -4), 4.5, eyePaint);
    canvas.drawCircle(const Offset(8, -4), 4.5, eyePaint);

    // رسم فم شرير
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 6), width: 16, height: 5),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withOpacity(0.5),
    );
  }
}
