import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class PlayerController extends PositionComponent with TapCallbacks, DragCallbacks {
  // متغيرات الحركة
  bool left = false;
  bool right = false;
  bool up = false;
  bool down = false;
  bool fire = false;

  // ألوان اللاعب
  final Paint bodyPaint = Paint()..color = const Color(0xFF00FF57);
  final Paint glowPaint = Paint()..color = Colors.white.withOpacity(0.25);

  // أزرار التحكم الافتراضية
  late final VirtualJoystick _joystick;

  PlayerController({
    required super.position,
  }) : super(
          size: Vector2(40, 40),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // إنشاء عصا التحكم (Joystick)
    _joystick = VirtualJoystick(
      onUpdate: (direction) {
        // تحديث متغيرات الحركة بناءً على اتجاه العصا
        left = direction.x < -0.5;
        right = direction.x > 0.5;
        up = direction.y < -0.5;
        down = direction.y > 0.5;
        fire = false; // عصا التحكم لا تطلق النار
      },
    );
    add(_joystick);
  }

  // دالة لضبط المدخلات (إذا كنت تستخدم لوحة مفاتيح خارجية)
  void setInput(bool l, bool r, bool u, bool d, bool f) {
    left = l;
    right = r;
    up = u;
    down = d;
    fire = f;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // رسم جسم اللاعب
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      bodyPaint,
    );

    // رسم توهج حول اللاعب
    canvas.drawCircle(
      const Offset(0, 0),
      8,
      glowPaint,
    );

    // رسم العيون (لمسة جمالية)
    canvas.drawCircle(
      const Offset(-6, -6),
      5,
      Paint()..color = Colors.white.withOpacity(0.55),
    );
    canvas.drawCircle(
      const Offset(6, -6),
      5,
      Paint()..color = Colors.white.withOpacity(0.55),
    );
  }
}

// ------------------------------------------------------------------
// كلاس مساعد: عصا تحكم لمسية (Joystick)
// ------------------------------------------------------------------
class VirtualJoystick extends Component with DragCallbacks {
  final void Function(Vector2 direction) onUpdate;
  Vector2 _dragPosition = Vector2.zero();
  Vector2 _position = Vector2.zero();
  
  VirtualJoystick({required this.onUpdate});

  @override
  void onLoad() {
    super.onLoad();
    // نضع العصا في الزاوية اليسرى السفلية للشاشة (يمكنك تغيير الموقع هنا)
    _position = Vector2(80, 80); 
  }

  @override
  void render(Canvas canvas) {
    // رسم خلفية العصا
    canvas.drawCircle(
      Offset(_position.x, _position.y),
      50,
      Paint()..color = Colors.white.withOpacity(0.1),
    );
    
    // رسم مقبض العصا
    final dragOffset = _dragPosition.clamp(
      Vector2(-35, -35),
      Vector2(35, 35),
    );
    
    canvas.drawCircle(
      Offset(_position.x + dragOffset.x, _position.y + dragOffset.y),
      25,
      Paint()..color = Colors.white.withOpacity(0.3),
    );
  }

  @override
  void onDragStart(DragStartInfo info) {
    super.onDragStart(info);
    _updateDrag(info.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateInfo info) {
    super.onDragUpdate(info);
    _updateDrag(info.localPosition);
  }

  @override
  void onDragEnd(DragEndInfo info) {
    super.onDragEnd(info);
    _dragPosition = Vector2.zero();
    onUpdate(Vector2.zero()); // توقف عند رفع الإصبع
  }

  void _updateDrag(Vector2 localPosition) {
    final diff = localPosition - _position;
    _dragPosition = diff;
    onUpdate(diff);
  }
}
