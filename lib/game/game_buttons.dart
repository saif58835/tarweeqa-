import 'package:flame/components.dart';
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
    
    // رسم دائرة الزر
    canvas.drawCircle(center, 35, paint);
    
    // رسم رمز القنبلة
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 10, innerPaint);
    canvas.drawLine(
      Offset(center.dx, center.dy - 5), 
      Offset(center.dx, center.dy + 5), 
      innerPaint
    );
  }

  @override
  void onTapDown(TapDownInfo info) {
    // عند الضغط، يستدعي دالة القنبلة في اللعبة
    gameRef.shootBomb(); 
  }
}

// زر تبديل السلاح
class SwitchWeaponButton extends Component with TapCallbacks {
  final BattleGame gameRef;
  
  SwitchWeaponButton({required this.gameRef});

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.amber;
    final center = Offset(gameRef.size.x - 140, gameRef.size.y - 70);
    
    canvas.drawCircle(center, 35, paint);
    
    // رسم رمز التبديل
    final textPainter = TextPainter(
      text: const TextSpan(text: "⚡", style: TextStyle(fontSize: 30)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - 15, center.dy - 15));
  }

  @override
  void onTapDown(TapDownInfo info) {
    // عند الضغط، يستدعي دالة تبديل السلاح
    print("تم تبديل السلاح");
  }
}
