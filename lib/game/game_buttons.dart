import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'battle_game.dart';

// زر القنبلة
class BombButton extends Component with TapCallbacks {
  final BattleGame gameRef;

  BombButton({required this.gameRef});

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.redAccent;
    final center = Offset(gameRef.size.x - 70, gameRef.size.y - 70);

    canvas.drawCircle(center, 35, paint);

    final innerPaint = Paint()..color = Colors.white;

    canvas.drawCircle(center, 10, innerPaint);

    canvas.drawLine(
      Offset(center.dx, center.dy - 5),
      Offset(center.dx, center.dy + 5),
      innerPaint,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    gameRef.launchBomb();
  }
}


// زر تبديل السلاح
class SwitchWeaponButton extends Component with TapCallbacks {
  final BattleGame gameRef;

  SwitchWeaponButton({required this.gameRef});

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.amber;

    final center = Offset(
      gameRef.size.x - 140,
      gameRef.size.y - 70,
    );

    canvas.drawCircle(center, 35, paint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: "⚡",
        style: TextStyle(
          fontSize: 30,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - 15, center.dy - 15),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    gameRef.switchWeapon();
  }
}
