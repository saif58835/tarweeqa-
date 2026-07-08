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
  final bool isSinglePlayer; // متغير جديد للاختيار

  late final PlayerController player;
  late final EnemyController enemy; // في حالة العدو الروبوت
  late final PlayerController remotePlayer; // في حالة اللاعب الصديق
  late final HudOverlay hud;

  final Random random = Random();
  final List<BulletController> bullets = [];

  int score = 0;
  bool gameOver = false;

  BattleGame({
    required this.networkService,
    this.isSinglePlayer = false, // افتراضي: ضد صديق
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
        isLocal: false, // ليس أنت، بل الصديق
      );
      add(remotePlayer);
    }

    hud = HudOverlay();
    add(hud);
  }

  void shoot() {
    if (gameOver) return;

    final bullet = BulletController(
      position: Vector2(player.position.x + 32, player.position.y),
      direction: Vector2(1, 0),
    );

    bullets.add(bullet);
    add(bullet);

    networkService.sendShoot(
      x: bullet.position.x,
      y: bullet.position.y,
      dx: 1,
      dy: 0,
    );
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
    // فحص التصادم مع الخصم
    if (isSinglePlayer) {
      // مع الروبوت
      for (final bullet in bullets.toList()) {
        if (bullet.position.distanceTo(enemy.position) < 30) {
          bullet.removeFromParent();
          bullets.remove(bullet);
          enemy.hit();

          if (enemy.health <= 0) {
            score += 10;
            enemy.reset(random, size);
          }
        }
      }

      if (player.position.distanceTo(enemy.position) < 32) {
        gameOver = true;
        networkService.sendGameOver('remote');
      }
    } else {
      // مع الصديق
      for (final bullet in bullets.toList()) {
        if (bullet.position.distanceTo(remotePlayer.position) < 30) {
          bullet.removeFromParent();
          bullets.remove(bullet);
          // هنا نرسل للشبكة أن الرصاصة أصابت الصديق
        }
      }

      if (player.position.distanceTo(remotePlayer.position) < 32) {
        gameOver = true;
        networkService.sendGameOver('remote');
      }
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    shoot();
  }
}
