import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

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
  late final HudOverlay hud;

  final Random random = Random();
  final List<BulletController> bullets = [];

  int score = 0;
  bool gameOver = false;
  double _enemyShootTimer = 0; // **جديد: مؤقت لإطلاق نار العدو**

  BattleGame({
    required this.networkService,
    this.isSinglePlayer = false, 
  });

  @override
  Color backgroundColor() => const Color(0xFF0F1020);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    // إنشاء اللاعب المحلي
    player = PlayerController(
      position: Vector2(100, size.y - 110),
      isLocal: true,
    );
    add(player);

    // منطق الاختيار: روبوت أم صديق
    if (isSinglePlayer) {
      // الوضع الفردي: أنشئ عدواً (روبوت)
      enemy = EnemyController(
        position: Vector2(size.x - 120, 110),
      );
      add(enemy);
    } else {
      // الوضع الجماعي: أنشئ مكاناً للاعب الصديق
      remotePlayer = PlayerController(
        position: Vector2(size.x - 120, 110),
        isLocal: false, 
      );
      add(remotePlayer);
    }

    hud = HudOverlay();
    add(hud);
  }

  // **جديد: دالة إطلاق النار تدعم تحديد من أطلق (أنت أم العدو)**
  void shoot(bool isEnemyBullet, Vector2 position, Vector2 direction) {
    if (gameOver) return;

    final bullet = BulletController(
      position: position,
      direction: direction,
      isEnemy: isEnemyBullet, // تمرير ما إذا كانت رصاصة عدو أم لا
    );

    bullets.add(bullet);
    add(bullet);

    // إرسال الشبكة فقط إذا كان اللاعب هو من أطلق
    if (!isEnemyBullet) {
      networkService.sendShoot(
        x: bullet.position.x,
        y: bullet.position.y,
        dx: 1,
        dy: 0,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameOver) return;

    const speed = 220.0;

    // 1. تحديث حركة اللاعب المحلي
    if (player.left) player.position.x -= speed * dt;
    if (player.right) player.position.x += speed * dt;
    if (player.up) player.position.y -= speed * dt;
    if (player.down) player.position.y += speed * dt;

    player.position.x = player.position.x.clamp(30, size.x - 30);
    player.position.y = player.position.y.clamp(90, size.y - 30);

    // 2. تحديث حركة الخصم
    if (isSinglePlayer) {
      // ضد الروبوت: يتبعك
      enemy.follow(player.position, dt, size);
      
      // **جديد: العدو يطلق النار**
      _enemyShootTimer += dt;
      if (_enemyShootTimer >= 0.8) {
        _enemyShootTimer = 0;
        // حساب اتجاه الرصاصة من العدو نحو اللاعب
        Vector2 dir = (player.position - enemy.position).normalized();
        shoot(true, enemy.position.clone(), dir);
      }
    } else {
      // ضد الصديق: يجب تحديث موقعه بناءً على بيانات الشبكة القادمة
      if (networkService.remotePlayer != null) {
        remotePlayer.position.x = networkService.remotePlayer!.x;
        remotePlayer.position.y = networkService.remotePlayer!.y;
      }
    }

    updateBullets(dt);
    checkCollisions();

    // إرسال حالة اللاعب للشبكة
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
        // 1. تصادم رصاصة اللاعب مع العدو
        if (!bullet.isEnemy && bullet.position.distanceTo(enemy.position) < 30) {
          bullet.removeFromParent();
          bullets.remove(bullet);
          enemy.hit();

          if (enemy.health <= 0) {
            score += 10;
            enemy.reset(random, size);
          }
        }
        
        // **جديد: 2. تصادم رصاصة العدو مع اللاعب**
        if (bullet.isEnemy && bullet.position.distanceTo(player.position) < 30) {
          bullet.removeFromParent();
          bullets.remove(bullet);
          player.health--; // تنقص صحة اللاعب

          if (player.health <= 0) {
            gameOver = true;
            networkService.sendGameOver('remote');
          }
        }
      } else {
        // منطق 1v1 مع صديق (للشبكة)
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
    // اللاعب يطلق النار (ليس عدواً)
    shoot(false, Vector2(player.position.x + 32, player.position.y), Vector2(1, 0));
  }
}
