import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// كلاس رسم الخريطة بالكود
class GameMap extends Component {
  final Vector2 screenSize;

  GameMap({required this.screenSize});

  @override
  void render(Canvas canvas) {
    // 1. رسم الأرضية (لون متدرج)
    final rect = Rect.fromLTWH(0, 0, screenSize.x, screenSize.y);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2C3E50), Color(0xFF1A252F)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    // 2. رسم خطوط الشبكة (لتعطي طابع ساحة قتال)
    final gridPaint = Paint()..color = Colors.white.withOpacity(0.05);
    for (double i = 0; i < screenSize.x; i += 80) {
      canvas.drawLine(Offset(i, 0), Offset(i, screenSize.y), gridPaint);
    }
    for (double j = 0; j < screenSize.y; j += 80) {
      canvas.drawLine(Offset(0, j), Offset(screenSize.x, j), gridPaint);
    }

    // 3. رسم جدران حدودية (لتمنع اللاعب من الخروج عن الحدود)
    final wallPaint = Paint()..color = Colors.cyan.withOpacity(0.3);
    canvas.drawRect(Rect.fromLTWH(0, 0, screenSize.x, 10), wallPaint); // جدار علوي
    canvas.drawRect(Rect.fromLTWH(0, screenSize.y - 10, screenSize.x, 10), wallPaint); // جدار سفلي
    canvas.drawRect(Rect.fromLTWH(0, 0, 10, screenSize.y), wallPaint); // جدار أيسر
    canvas.drawRect(Rect.fromLTWH(screenSize.x - 10, 0, 10, screenSize.y), wallPaint); // جدار أيمن

    // 4. رسم حواجز عشوائية في الخريطة
    final barrierPaint = Paint()..color = const Color(0xFF4A6572);
    final random = Random(123); // نفس الرقم يسحب نفس الحواجز كل مرة
    for (int i = 0; i < 10; i++) {
      final x = 100 + random.nextDouble() * (screenSize.x - 200);
      final y = 100 + random.nextDouble() * (screenSize.y - 200);
      final w = 40 + random.nextDouble() * 60;
      final h = 40 + random.nextDouble() * 60;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(8)),
        barrierPaint,
      );
    }
  }
}
