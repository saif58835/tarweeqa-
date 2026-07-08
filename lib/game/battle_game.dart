import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../network/network_service.dart';
import 'bullet_controller.dart';
import 'enemy_controller.dart';
import 'hud_overlay.dart';
import 'player_controller.dart';

class BattleGame extends FlameGame with TapDetector {
  final NetworkService networkService;
  final bool isSinglePlayer;

  late final PlayerController player;
  late final EnemyController enemy;
  late final PlayerController remotePlayer;
  
  // واجهة المستخدم
  late final HudOverlay hud;
  // لتشغيل الأصوات
  final AudioPlayer audioPlayer = AudioPlayer();

  final Random random = Random();
  final List<BulletController> bullets = [];

  int score = 0;
  int kills = 0;
  bool gameOver = false;
  double _enemyShootTimer = 0;
  double _playerFireCooldown = 0; // نظام التبريد (Cooldown)

  BattleGame({
    required this.networkService,
    this.isSinglePlayer = false,
  });

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E); // لون خلفية احتياطي

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    // رسم خلفية متحركة (Parallax) - سيتم تحويلها لصورة لاحقاً
    // مؤقتاً نستخدم مستطيلاً لطيفاً
    add(RectangleComponent(
      position: Vector2.zero(),
      size: size,
      paint: Paint()..color = const Color(0xFF16213E),
    ));

    player = PlayerController(position: Vector2(100, size.y - 110));
    add(player);

    if (isSinglePlayer) {
      enemy = EnemyController(position: Vector2(size.x - 120, 110));
      add(enemy);
    } else {
      remotePlayer = PlayerController(position: Vector2(size.x - 120, 110));
      add(remotePlayer);
    }

    hud = HudOverlay(gameRef: this); // تمرير اللعبة للـ Hud ليعرف النقاط
    add(hud);
  }

  void shoot(bool isEnemyBullet, Vector2 position, Vector2 direction) {
    if (gameOver) return;
    
    // نظام الطاقة: منع اللاعب من إطلاق النار بسرعة كبيرة
    if (!isEnemyBullet && _playerFireCooldown > 0) return;

    final bullet = BulletController(
      position: position,
      direction: direction,
      isEnemy: isEnemyBullet,
    );

    bullets.add(bullet);
    add(bullet);

    if (!isEnemyBullet) {
      _playerFireCooldown = 0.25; // يمكنه إطلاق النار كل ربع ثانية
      audioPlayer.play(AssetSource('sounds/shoot.wav')); // تشغيل صوت الرماية
      
      networkService.sendShoot(
        x: bullet.position.x,
        y: bullet.position.y,
        dx: 1,
        dy: 0,
      );
    }
  }

  // دالة خاصة لإطلاق القنبلة
  void shootBomb() {
    if (gameOver || _playerFireCooldown > 0) return;
    
    // هنا سنضع كود القنبلة لاحقاً (سنصنع BulletController خاص للقنبلة)
    print("تم إطلاق القنبلة!");
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameOver) return;

    // تحديث مؤقت التبريد (Cooldown)
    if (_playerFireCooldown > 0) _playerFireCooldown -= dt;

    const speed = 220.0;

    if (player.left) player.position.x -= speed * dt;
    if (player.right) player.position.x += speed * dt;
    if (player.up) player.position.y -= speed * dt;
    if (player.down) player.position.y += speed * dt;

    player.position.x = player.position.x.clamp(30, size.x - 30);
    player.position.y = player.position.y.clamp(90, size.y - 30);

    if (isSinglePlayer) {
      enemy.follow(player.position, dt, size);
      
      _enemyShootTimer += dt;
      if (_enemyShootTimer >= 0.8 - (kills * 0.01)) { // روبوت أسرع كلما زاد القتل
        _enemyShootTimer = 0;
        Vector2 dir = (player.position - enemy.position).normalized();
        shoot(true, enemy.position.clone(), dir);
      }
    } else {
      if (networkService.remotePlayer != null) {
        remotePlayer.position.x = networkService.remotePlayer!.x;
        remotePlayer.position.y = networkService.remotePlayer!.y;
      }
    }

    updateBullets(dt);
    checkCollisions();

    if (networkService.localPlayer != null) {
      networkService.sendState(
        networkService.localPlayer!.copyWith(
          x: player.position.x,
          y: player.position.y,
          health: player.health,
          score: score,
        ),
      );
    }
  }

  void updateBullets(double dt) {
    for (final bullet in bullets.toList()) {
      bullet.updateBullet(dt);

      if (bullet.position.x > size.x + 60 ||
          bullet.position.x < -60 ||
          bullet.position.y > size.y + 60 ||
          bullet.position.y < -60) {
        bullet.removeFromParent();
        bullets.remove(bullet);
      }
    }
  }

  void checkCollisions() {
    for (final bullet in bullets.toList()) {
      if (isSinglePlayer) {
        // إصابة العدو
        if (!bullet.isEnemy && bullet.position.distanceTo(enemy.position) < 30) {
          bullet.removeFromParent();
          bullets.remove(bullet);
          enemy.hit();
          audioPlayer.play(AssetSource('sounds/hit.wav'));

          if (enemy.health <= 0) {
            score += 10;
            kills++;
            enemy.reset(random, size);
          }
        }
        
        // إصابة اللاعب
        if (bullet.isEnemy && bullet.position.distanceTo(player.position) < 30) {
          bullet.removeFromParent();
          bullets.remove(bullet);
          player.health--;

          if (player.health <= 0) {
            gameOver = true;
            networkService.sendGameOver('remote');
          }
        }
      } else {
        if (!bullet.isEnemy && bullet.position.distanceTo(remotePlayer.position) < 30) {
          bullet.removeFromParent();
          bullets.remove(bullet);
        }
        if (bullet.isEnemy && bullet.position.distanceTo(player.position) < 30) {
          bullet.removeFromParent();
          bullets.remove(bullet);
        }
      }
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    // إطلاق النار
    shoot(false, Vector2(player.position.x + 32, player.position.y), Vector2(1, 0));
  }
}
