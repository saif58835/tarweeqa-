import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HudOverlay extends Component {
  // 1. إضافة GameRef للوصول لحالة اللعبة
  @override
  void onLoad() {
    super.onLoad();
  }

  // متغيرات النصوص
  final TextPaint _scoreText = TextPaint(
    style: const TextStyle(
      color: Colors.cyanAccent,
      fontSize: 20,
    ),
  );

  final TextPaint _healthText = TextPaint(
    style: const TextStyle(
      color: Colors.redAccent,
      fontSize: 20,
    ),
  );

  final TextPaint _statusText = TextPaint(
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 14,
    ),
  );

  // **2. الطريقة الصحيحة لجلب البيانات من اللعبة**
  // بدلاً من استيراد BattleGame، سنستخدم gameRef للوصول للبيانات
  bool _getGameOverStatus() {
    // نقوم بجلب الحالة من اللعبة (افتراضي أنها false إذا لم نجدها)
    // ملاحظة: في الإصدارات الحديثة من Flame، نستخدم gameRef للحصول على اللعبة الأم
    // لكن لكي يعمل هذا الكود، يجب أن تكون BattleGame هي اللعبة الرئيسية.
    // سنقوم بإنشاء متغير لنتحقق من حالة اللعبة.
    return false; // مؤقتاً نضعها false حتى نبرمج المعركة بشكل كامل
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // رسم النقاط (النص الأول)
    _scoreText.render(
      canvas,
      "Score: 0", // يمكنك لاحقاً وضع: gameRef.score
      Vector2(16, 16),
    );

    // رسم الصحة (النص الثاني)
    _healthText.render(
      canvas,
      "Health: 3", // يمكنك لاحقاً وضع: gameRef.player.health
      Vector2(16, 40),
    );

    // رسم حالة اللعبة (إذا انتهت)
    if (_getGameOverStatus()) {
      _statusText.render(
        canvas,
        "Game Over!",
        Vector2(16, 60),
      );
    }
  }
}
