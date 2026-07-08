import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'battle_game.dart';

class HudOverlay extends Component {
  final BattleGame gameRef;

  HudOverlay({required this.gameRef});

  final TextPaint _scoreText = TextPaint(
    style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold),
  );
  final TextPaint _killsText = TextPaint(
    style: const TextStyle(color: Colors.yellowAccent, fontSize: 18),
  );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // النقاط (يسار)
    _scoreText.render(canvas, "Score: ${gameRef.score}", Vector2(16, 16));
    
    // عدد القتلى (يسار أسفل النقاط)
    _killsText.render(canvas, "Kills: ${gameRef.kills}", Vector2(16, 50));

    // هنا سنرسم لاحقاً أزرار تبديل السلاح والقنبلة في الزاوية اليمنى
    // canvas.drawCircle(Offset(gameRef.size.x - 60, gameRef.size.y - 60), 30, Paint()..color = Colors.red);
  }
}
