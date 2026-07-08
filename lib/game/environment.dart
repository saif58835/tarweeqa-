import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SkyBackground extends Component {
  final Vector2 screenSize;
  
  SkyBackground({required this.screenSize});

  double _cloudOffset = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    // تحريك السحب ببطء
    _cloudOffset += dt * 20.0;
  }

  @override
  void render(Canvas canvas) {
    // 1. السماء الزرقاء
    final rect = Rect.fromLTWH(0, 0, screenSize.x, screenSize.y);
    final skyPaint = Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // 2. رسم غيوم بيضاء بسيطة
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.4);
    final random = Random(123);
    for (int i = 0; i < 8; i++) {
      final x = (i * 150 + _cloudOffset) % (screenSize.x + 200) - 100;
      final y = 50 + random.nextDouble() * (screenSize.y - 100);
      canvas.drawCircle(Offset(x, y), 30 + random.nextDouble() * 40, cloudPaint);
      canvas.drawCircle(Offset(x - 40, y - 10), 25 + random.nextDouble() * 30, cloudPaint);
      canvas.drawCircle(Offset(x + 40, y + 10), 20 + random.nextDouble() * 30, cloudPaint);
    }
  }
}
