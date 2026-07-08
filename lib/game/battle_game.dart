import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../network/network_service.dart';
import 'bullet_controller.dart';
import 'enemy_controller.dart';
import 'hud_overlay.dart';
import 'player_controller.dart';
import 'game_buttons.dart';
import 'environment.dart';

class BattleGame extends FlameGame with TapDetector {
  final NetworkService networkService;
  final bool isSinglePlayer;

  late final PlayerController player;
  late final EnemyController enemy;
  late final PlayerController remotePlayer;
  late final HudOverlay hud;
  late final GameMap gameMap;

  final AudioPlayer audioPlayer = AudioPlayer();

  final Random random = Random();
  final List<BulletController> bullets = [];

  int score = 0;
  int kills = 0;
  bool gameOver = false;
  double _enemyShootTimer = 0;
  double _playerFireCooldown = 0;

  int _currentWeaponIndex = 0;
  final List<String> _weapons = ['Pistol', 'Sniper', 'SMG'];
  double _currentZoom = 1.0;

  bool _bombCooldown = false;
  double _bombTimer = 0;

  BattleGame({
    required this.networkService,
    this.isSinglePlayer = false,
  });

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    gameMap = GameMap(screenSize: size);
    add(gameMap);

    player = PlayerController(position: Vector2(100, size.y - 110));
    add(player);

    if (isSinglePlayer) {
      enemy = EnemyController(position: Vector2(size.x - 120, 110));
      add(enemy);
    } else {
      remotePlayer = PlayerController(position: Vector2(size.x - 120, 110));
      add(remotePlayer);
    }

    hud = HudOverlay(gameRef: this);
    add(hud);

    add(BombButton(gameRef: this));
    add(SwitchWeaponButton(gameRef: this));
  }

  void switchWeapon() {
    _currentWeaponIndex = (_currentWeaponIndex + 1) % _weapons.length;
    print("السلاح الحالي: ${_weapons[_currentWeaponIndex]}");
    
    if (_weapons[_currentWeaponIndex] == 'Sniper') {
      _currentZoom = 1.6;
    } else {
      _currentZoom = 1.0;
    }
    camera.zoom = _currentZoom;
  }

  void shoot(bool isEnemyBullet, Vector2 position, Vector2 direction) {
    if (gameOver) return;
    if (!isEnemyBullet && _playerFireCooldown > 0) return;

    String currentWeapon = isEnemyBullet ? 'Enemy' : _weapons[_currentWeaponIndex];

    final bullet = BulletController(
      position: position,
      direction: direction,
      isEnemy: isEnemyBullet,
      weaponType: currentWeapon, // تمرير نوع السلاح للرصاصة
    );

    bullets.add(bullet);
    add(bullet);

    if (!isEnemyBullet) {
      // تحديد سرعة الرماية والصوت حسب السلاح
      if (_weapons[_currentWeaponIndex] == 'SMG') {
        _playerFireCooldown = 0.08;
        audioPlayer.play(AssetSource('sounds/smg_shot.wav')); // صوت رشاش (خيالي حالياً)
      } else if (_weapons[_currentWeaponIndex] == 'Sniper') {
        _playerFireCooldown = 1.2;
        audioPlayer.play(AssetSource('sounds/sniper_shot.wav')); // صوت قناصة (خيالي حالياً)
      } else {
        _playerFireCooldown = 0.25;
        audioPlayer.play(AssetSource('sounds/pistol_shot.wav')); // صوت مسدس (خيالي حالياً)
      }

      networkService.sendShoot(
        x: bullet.position.x,
        y: bullet.position.y,
        dx: 1,
        dy: 0,
      );
    }
  }

  void launchBomb() {
    if (gameOver || _bombCooldown) return;
    _bombCooldown = true;
    _bombTimer = 3.0;
    audioPlayer.play(AssetSource('sounds/bomb_throw.wav')); // صوت رمي القنبلة
  }

  void _detonateBomb() {
    audioPlayer.play(AssetSource('sounds/bomb_explode.wav')); // صوت الانفجار
    final blast = CircleComponent(
      radius: 120,
      position: player.position.clone(),
      paint: Paint()..color = Colors.orange.withOpacity(0.8),
    );
    add(blast);
    Future.delayed(const Duration(seconds: 1), () => blast.removeFromParent());

    if (isSinglePlayer && player.position.distanceTo(enemy.position) < 120) {
      enemy.hit(); enemy.hit(); enemy.hit();
      score += 30;
    }
    if (isSinglePlayer && player.position.distanceTo(player.position) < 120) {
      player.health -= 1;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameOver) return;

    if (_playerFireCooldown > 0) _playerFireCooldown -= dt;

    if (_bombCooldown) {
      _bombTimer -= dt;
      if (_bombTimer <= 0) {
        _bombCooldown = false;
        _detonateBomb();
      }
    }

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
      if (_enemyShootTimer >= 0.8 - (kills * 0.01)) {
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
      if (bullet.position.x > size.x + 60 || bullet.position.x < -60 ||
          bullet.position.y > size.y + 60 || bullet.position.y < -60) {
        bullet.removeFromParent();
        bullets.remove(bullet);
      }
    }
  }

  void checkCollisions() {
    for (final bullet in bullets.toList()) {
      if (isSinglePlayer) {
        if (!bullet.isEnemy && bullet.position.distanceTo(enemy.position) < 30) {
          bullet.removeFromParent();
          bullets.remove(bullet);
          enemy.hit();
          audioPlayer.play(AssetSource('sounds/enemy_hit.wav')); // صوت إصابة العدو
          if (enemy.health <= 0) {
            score += 10;
            kills++;
            enemy.reset(random, size);
          }
        }
        if (bullet.isEnemy && bullet.position.distanceTo(player.position) < 30) {
          bullet.removeFromParent();
          bullets.remove(bullet);
          player.health--;
          audioPlayer.play(AssetSource('sounds/player_hit.wav')); // صوت إصابة اللاعب
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
    shoot(false, Vector2(player.position.x + 32, player.position.y), Vector2(1, 0));
  }
}
