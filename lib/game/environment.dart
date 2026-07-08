import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// أنواع الخرائط المختلفة
enum MapType { Desert, Forest, City }

class GameMap extends Component {
  final Vector2 screenSize;
  final MapType mapType;

  GameMap({
    required this.screenSize, 
    // إذا لم تحدد نوع الخريطة، سيختار واحدة عشوائياً
    MapType? mapType,
  }) : mapType = mapType ?? MapType.values[Random().nextInt(MapType.values.length)];

  // ألوان الحواجز والأرضية
  final Paint _groundPaint = Paint();
  final Paint _barrierPaint = Paint()..color = const Color(0xFF4A6572);

  @override
  void render(Canvas canvas) {
    _drawGround(canvas);
    _drawGrid(canvas);
    _drawWalls(canvas);
    _drawBarriers(canvas);
  }

  void _drawGround(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, screenSize.x, screenSize.y);
    
    // اختيار ألوان الأرضية حسب نوع الخريطة
    switch (mapType) {
      case MapType.Desert:
        _groundPaint.shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4A373), Color(0xFFE9EDC9)],
        ).createShader(rect);
        break;
      case MapType.Forest:
        _groundPaint.shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
        ).createShader(rect);
        break;
      case MapType.City:
        _groundPaint.shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF495057), Color(0xFF6C757D)],
        ).createShader(rect);
        break;
    }
    canvas.drawRect(rect, _groundPaint);
  }

  void _drawGrid(Canvas canvas) {
    final gridPaint = Paint()..color = Colors.white.withOpacity(0.05);
    for (double i = 0; i < screenSize.x; i += 80) {
      canvas.drawLine(Offset(i, 0), Offset(i, screenSize.y), gridPaint);
    }
    for (double j = 0; j < screenSize.y; j += 80) {
      canvas.drawLine(Offset(0, j), Offset(screenSize.x, j), gridPaint);
    }
  }

  void _drawWalls(Canvas canvas) {
    final wallPaint = Paint()..color = Colors.cyan.withOpacity(0.3);
    canvas.drawRect(Rect.fromLTWH(0, 0, screenSize.x, 10), wallPaint);
    canvas.drawRect(Rect.fromLTWH(0, screenSize.y - 10, screenSize.x, 10), wallPaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, 10, screenSize.y), wallPaint);
    canvas.drawRect(Rect.fromLTWH(screenSize.x - 10, 0, 10, screenSize.y), wallPaint);
  }

  void _drawBarriers(Canvas canvas) {
    // اختيار ألوان الحواجز حسب نوع الخريطة
    switch (mapType) {
      case MapType.Desert:
        _barrierPaint.color = const Color(0xFFBC6C25);
        break;
      case MapType.Forest:
        _barrierPaint.color = const Color(0xFF1B4332);
        break;
      case MapType.City:
        _barrierPaint.color = const Color(0xFF343A40);
        break;
    }

    // رسم الحواجز بشكل مختلف لكل خريطة (لكل خريطة توزيع عشوائي خاص بها)
    // استخدام رقم ثابت (seed) لكل خريطة لضمان ظهورها بنفس الشكل كل مرة
    final random = Random(mapType.index * 12345); 
    
    // عدد الحواجز يختلف حسب الخريطة
    int barrierCount;
    switch (mapType) {
      case MapType.Desert: barrierCount = 12; break; // صحراء حواجز كثيرة
      case MapType.Forest: barrierCount = 8; break;  // غابة حواجز متوسطة
      case MapType.City: barrierCount = 6; break;    // مدينة حواجز قليلة
    }

    for (int i = 0; i < barrierCount; i++) {
      final x = 100 + random.nextDouble() * (screenSize.x - 200);
      final y = 100 + random.nextDouble() * (screenSize.y - 200);
      
      // في المدينة، الحواجز تكون مربعة. في الصحراء والغابة، حواجز دائرية.
      if (mapType == MapType.City) {
        final size = 40 + random.nextDouble() * 80;
        canvas.drawRect(
          Rect.fromLTWH(x, y, size, size),
          _barrierPaint,
        );
      } else {
        final radius = 30 + random.nextDouble() * 50;
        canvas.drawCircle(
          Offset(x, y),
          radius,
          _barrierPaint,
        );
      }
    }
  }
}
