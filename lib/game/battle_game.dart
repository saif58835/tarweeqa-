import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class BattleGame extends FlameGame with TapDetector, HasCollisionDetection {
  late final Player player;
  late final Enemy enemy;
  late final HudText scoreText;
  late final HudText infoText;

  int score = 0;
  bool gameOver = false;
  final Random _random = Random();

  @override
  Color backgroundColor() => const Color(0xFF0F1020);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.topLeft;

    player = Player(
      position: Vector2(60, size.y - 120),
    );

    enemy = Enemy(
      position: Vector2(size.x - 120, size.y - 120),
    );

    scoreText = HudText(
      text: 'Score: 0',
      position: Vector2(16, 16),
      color: Colors.white,
      fontSize: 20,
    );

    infoText = HudText(
      text: 'Tap to shoot • Arrows move',
      position: Vector2(16, 44),
      color: Colors.cyanAccent,
      fontSize: 14,
    );

    addAll([player, enemy, scoreText, infoText]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameOver) return;

    enemy.moveTowardsPlayer(player.position, dt, size);

    for (final bullet in player.bullets.toList()) {
      if (bullet.position.distanceTo(enemy.position) < 28) {
        bullet.removeFromParent();
        player.bullets.remove(bullet);
        enemy.takeDamage();
        if (enemy.health <= 0) {
          score += 10;
          scoreText.text = 'Score: $score';
          enemy.respawn(size, _random);
          player.spawnFlash();
        }
      }
    }

    if (player.health <= 0) {
      gameOver = true;
      infoText
        ..text = 'Game Over'
        ..color = Colors.redAccent
        ..fontSize = 22;
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (gameOver) return;
    player.shoot();
  }
}

class Player extends PositionComponent with HasGameRef<BattleGame> {
  final List<Bullet> bullets = [];
  final Paint _paint = Paint()..color = const Color(0xFF00E5FF);
  int health = 3;
  bool _flash = false;

  Player({required super.position})
      : super(
          size: Vector2(46, 46),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    final speed = 260.0;

    if (gameRef.keyboard.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
      position.x -= speed * dt;
    }
    if (gameRef.keyboard.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
      position.x += speed * dt;
    }
    if (gameRef.keyboard.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
      position.y -= speed * dt;
    }
    if (gameRef.keyboard.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
      position.y += speed * dt;
    }

    position.x = position.x.clamp(25, gameRef.size.x - 25);
    position.y = position.y.clamp(80, gameRef.size.y - 25);

    for (final bullet in bullets.toList()) {
      bullet.updateBullet(dt);
      if (bullet.position.x > gameRef.size.x + 50 ||
          bullet.position.x < -50 ||
          bullet.position.y < -50 ||
          bullet.position.y > gameRef.size.y + 50) {
        bullet.removeFromParent();
        bullets.remove(bullet);
      }
    }
  }

  void shoot() {
    final bullet = Bullet(
      position: Vector2(position.x + 30, position.y),
      direction: Vector2(1, 0),
    );
    bullets.add(bullet);
    gameRef.add(bullet);
  }

  void spawnFlash() {
    _flash = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      _flash = false;
    });
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = _flash ? Colors.white : _paint.color
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      paint,
    );

    canvas.drawCircle(
      const Offset(10, -6),
      6,
      Paint()..color = Colors.white.withOpacity(0.4),
    );
  }
}

class Enemy extends PositionComponent with HasGameRef<BattleGame> {
  int health = 3;
  final Paint _paint = Paint()..color = const Color(0xFFFF4D6D);

  Enemy({required super.position})
      : super(
          size: Vector2(42, 42),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  void moveTowardsPlayer(Vector2 target, double dt, Vector2 screenSize) {
    final dir = target - position;
    if (dir.length > 1) {
      dir.normalize();
      position += dir * 90 * dt;
    }

    position.x = position.x.clamp(25, screenSize.x - 25);
    position.y = position.y.clamp(80, screenSize.y - 25);
  }

  void takeDamage() {
    health--;
  }

  void respawn(Vector2 screenSize, Random random) {
    health = 3;
    position = Vector2(
      screenSize.x * 0.55 + random.nextDouble() * (screenSize.x * 0.35),
      120 + random.nextDouble() * (screenSize.y * 0.55),
    );
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
      _paint,
    );

    canvas.drawCircle(
      const Offset(0, 0),
      4,
      Paint()..color = Colors.white,
    );
  }
}

class Bullet extends PositionComponent with HasGameRef<BattleGame> {
  final Vector2 direction;
  final Paint _paint = Paint()..color = Colors.amberAccent;
  final double speed = 420;

  Bullet({
    required super.position,
    required this.direction,
  }) : super(
          size: Vector2(14, 6),
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
      _paint,
    );
  }
}

class HudText extends TextComponent {
  HudText({
    required super.text,
    required Vector2 position,
    required Color color,
    required double fontSize,
  }) : super(
          position: position,
          textRenderer: TextPaint(
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
}
