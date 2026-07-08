import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'battle_game.dart';

class HudOverlay extends PositionComponent with HasGameRef<BattleGame> {
  late final TextComponent scoreText;
  late final TextComponent healthText;
  late final TextComponent statusText;

  HudOverlay()
      : super(
          anchor: Anchor.topLeft,
          position: Vector2.zero(),
        );

  @override
  Future<void> onLoad() async {
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(16, 16),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    healthText = TextComponent(
      text: 'Health: 3',
      position: Vector2(16, 42),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    statusText = TextComponent(
      text: 'Tap to shoot',
      position: Vector2(16, 68),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );

    addAll([scoreText, healthText, statusText]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    scoreText.text = 'Score: ${gameRef.score}';
    healthText.text = 'Health: ${gameRef.player.health}';

    if (gameRef.gameOver) {
      statusText.text = 'Game Over';
      statusText.textRenderer = TextPaint(
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      statusText.text = 'Arrows move • Space or Tap shoots';
      statusText.textRenderer = TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      );
    }
  }
}
