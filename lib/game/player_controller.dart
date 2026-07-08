import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class PlayerController extends PositionComponent with TapCallbacks, DragCallbacks {
  bool left = false;
  bool right = false;
  bool up = false;
  bool down = false;
  bool fire = false;

  final Paint bodyPaint = Paint()..color = const Color(0xFF00FF57);
  final Paint cockpitPaint = Paint()..color = Colors.cyan;

  late final VirtualJoystick _joystick;

  PlayerController({
    required super.position,
  }) : super(
          size: Vector2(44, 44), // حجم الطائرة
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // عصا التحكم في الزاوية اليسرى
    _joystick = VirtualJoystick(
      onUpdate: (direction) {
        left = direction.x < -0.5;
        right = direction.x > 0.5;
        up = direction.y < -0.5;
        down = direction.y > 0.5;
        fire = false;
      },
    );
    add(_joystick);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // رسم جسم الطائرة
    final path = Path();
    // مقدمة الطائرة (مثلث متجه للأمام)
    path.moveTo(22, 0);
    path.lineTo(-22, -18);
    path.lineTo(-10, 0);
    path.lineTo(-22, 18);
    path.close();

    // إضافة ذيل الطائرة
    path.moveTo(-16, -8);
    path.lineTo(-26, -14);
    path.lineTo(-26, -2);
    path.close();
    path.moveTo(-16, 8);
    path.lineTo(-26, 14);
    path.lineTo(-26, 2);
    path.close();

    canvas.drawPath(path, bodyPaint);

    // رسم قمرة القيادة (الزجاج)
    canvas.drawCircle(const Offset(8, 0), 8, cockpitPaint);
  }
}

// (اترك كلاس VirtualJoystick في نهاية الملف كما هو - بدون تغيير)
class VirtualJoystick extends Component with DragCallbacks {
  final void Function(Vector2 direction) onUpdate;
  Vector2 _dragPosition = Vector2.zero();
  Vector2 _position = Vector2.zero();
  
  VirtualJoystick({required this.onUpdate});

  @override
  void onLoad() {
    super.onLoad();
    _position = Vector2(80, 80); 
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(_position.x, _position.y), 50, Paint()..color = Colors.white.withOpacity(0.1));
    final dragOffset = _dragPosition.clamp(Vector2(-35, -35), Vector2(35, 35));
    canvas.drawCircle(Offset(_position.x + dragOffset.x, _position.y + dragOffset.y), 25, Paint()..color = Colors.white.withOpacity(0.3));
  }

  @override
  void onDragStart(DragStartInfo info) { _updateDrag(info.localPosition); }
  @override
  void onDragUpdate(DragUpdateInfo info) { _updateDrag(info.localPosition); }
  @override
  void onDragEnd(DragEndInfo info) {
    _dragPosition = Vector2.zero();
    onUpdate(Vector2.zero());
  }
  void _updateDrag(Vector2 localPosition) {
    final diff = localPosition - _position;
    _dragPosition = diff;
    onUpdate(diff);
  }
}
