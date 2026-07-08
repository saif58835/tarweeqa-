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
  late final HudOverlay hud;
  late final SkyBackground skyBg; // خلفية السماء

  // قائمة متعددة للأعداء بدلاً من عدو واحد
  final List<EnemyController> enemies = [];
  double _enemySpawnTimer = 0.0;
  static const double maxEnemies = 5; // أقصى عدد للأعداء في وقت واحد

  final AudioPlayer audioPlayer = AudioPlayer();
  final Random random = Random();
  final List<BulletController> bullets = [];

  int score = 0;
  int kills = 0;
  bool gameOver = false;
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
  Color backgroundColor() => const Color(0xFF4facfe);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    // إضافة سماء جوية
    skyBg = SkyBackground(screenSize: size);
    add(skyBg);

    // طائرة اللاعب في منتصف الشاشة تقريباً
    player = PlayerController(position: Vector2(100, size.y / 2));
    add(player);

    hud = HudOverlay(gameRef: this);
    add(hud);

    add(BombButton(gameRef: this));
    add(SwitchWeaponButton(gameRef: this));
  }

  // تمركز عدو جديد من حواف الشاشة
  void spawnEnemy() {
    if (enemies.length >= maxEnemies) return;
    
    double x, y;
    // يظهر العدو من اليمين أو اليسار أو الأعلى
    int side = random.nextInt(3);
    if (side == 0) { // من اليمين
      x = size.x + 50;
      y = 50 + random.nextDouble() * (size.y - 100);
    } else if (side == 1) { // من اليسار
      x = -50;
      y = 50 + random.nextDouble() * (size.y - 100);
    } else { // من الأعلى
      x = 50 + random.nextDouble() * (size.x - 100);
      y = -50;
    }

    final enemy = EnemyController(position: Vector2(x, y));
    enemies.add(enemy);
    add(enemy);
  }

  void switchWeapon() {
    _currentWeaponIndex = (_currentWeaponIndex + 1) % _weapons.length;
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
      weaponType: currentWeapon,
    );
    bullets.add(bullet);
    add(bullet);

    if (!isEnemyBullet) {
      if (_weapons[_currentWeaponIndex] == 'SMG') _playerFireCooldown = 0.08;
      else if (_weapons[_currentWeaponIndex] == 'Sniper') _playerFireCooldown = 1.2;
      else _playerFireCooldown = 0.25;
      
      networkService.sendShoot(x: bullet.position.x, y: bullet.position.y, dx: 1, dy: 0);
    }
  }

  void launchBomb() {
    if (gameOver || _bombCooldown) return;
    _bombCooldown = true;
    _bombTimer = 3.0;
  }

  void _detonateBomb() {
    final blast = CircleComponent(radius: 120, position: player.position.clone(), paint: Paint()..color = Colors.orange.withOpacity(0.8));
    add(blast);
    Future.delayed(const Duration(seconds: 1), () => blast.removeFromParent());

    for (final enemy in enemies.toList()) {
      if (player.position.distanceTo(enemy.position) < 120) {
        enemy.hit(); enemy.hit(); enemy.hit();
        score += 30;
      }
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

    // تمركز عدو جديد كل ثانية ونصف
    _enemySpawnTimer += dt;
    if (_enemySpawnTimer >= 1.5) {
      _enemySpawnTimer = 0;
      spawnEnemy();
    }

    const speed = 220.0;
    // طيران حر 360 درجة للاعب (لقد أزلنا القيود الأرضية)
    if (player.left) player.position.x -= speed * dt;
    if (player.right) player.position.x += speed * dt;
    if (player.up) player.position.y -= speed * dt;
    if (player.down) player.position.y += speed * dt;
    
    // حدود الشاشة فقط
    player.position.x = player.position.x.clamp(20, size.x - 20);
    player.position.y = player.position.y.clamp(20, size.y - 20);

    // تحديث حركة كل الأعداء وإطلاق النار
    for (final enemy in enemies.toList()) {
      enemy.follow(player.position, dt, size);
      
      if (_enemyShootTimer >= 0.8 - (kills * 0.01)) {
        Vector2 dir = (player.position - enemy.position).normalized();
        shoot(true, enemy.position.clone(), dir);
      }
    }
    _enemyShootTimer += dt;
    if (_enemyShootTimer >= 0.8 - (kills * 0.01)) {
      _enemyShootTimer = 0;
    }

    updateBullets(dt);
    checkCollisions();

    if (networkService.localPlayer != null) {
      networkService.sendState(networkService.localPlayer!.copyWith(
        x: player.position.x, y: player.position.y,
        health: player.health, score: score,
      ));
    }
  }
  double _enemyShootTimer = 0; // متغير للوقت (تم نقله للأعلى ليعمل)

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
      // فحص إصابة الأعداء برصاصك
      if (!bullet.isEnemy) {
        for (final enemy in enemies.toList()) {
          if (bullet.position.distanceTo(enemy.position) < 30) {
            bullet.removeFromParent();
            bullets.remove(bullet);
            enemy.hit();
            if (enemy.health <= 0) {
              score += 10;
              kills++;
              enemy.removeFromParent();
              enemies.remove(enemy);
            }
            break;
          }
        }
      }
      // فحص إصابتك برصاص العدو
      if (bullet.isEnemy && bullet.position.distanceTo(player.position) < 30) {
        bullet.removeFromParent();
        bullets.remove(bullet);
        player.health--;
        if (player.health <= 0) {
          gameOver = true;
          networkService.sendGameOver('remote');
        }
      }
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    shoot(false, Vector2(player.position.x + 32, player.position.y), Vector2(1, 0));
  }
}
