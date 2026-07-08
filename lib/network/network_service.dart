import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';

class NetworkService extends ChangeNotifier {
  late IO.Socket socket;
  String? _roomId;
  String? _playerId;
  String? _playerName;
  
  // قائمة اللاعبين الآخرين في الغرفة (بدون احتساب نفسك)
  List<Map<String, dynamic>> playersInRoom = [];

  // دالة الاتصال بالخادم
  void connectToServer(String serverUrl) {
    socket = IO.io(serverUrl, IO.OptionBuilder()
      .setTransports(['websocket']) // ضروري للاتصال السريع
      .disableAutoConnect()
      .build()
    );
    socket.connect();

    // الاستماع لتحديث قائمة اللاعبين عند دخول أحدهم أو خروجه
    socket.on('update_players', (data) {
      playersInRoom = List<Map<String, dynamic>>.from(data);
      // إزالة نفسي من القائمة حتى لا تظهر شخصيتي كعدو
      playersInRoom.removeWhere((player) => player['id'] == _playerId);
      notifyListeners(); // تحديث الواجهة الرسومية (لإظهار أسماء الأصدقاء)
    });

    // الاستماع لحركة أي لاعب آخر
    socket.on('opponent_moved', (data) {
      final index = playersInRoom.indexWhere((p) => p['id'] == data['playerId']);
      if (index != -1) {
        playersInRoom[index]['x'] = data['x'];
        playersInRoom[index]['y'] = data['y'];
        notifyListeners(); // تحديث موقع الخصم في اللعبة
      }
    });

    // الاستماع لإطلاق نار خصم
    socket.on('opponent_shoot', (data) {
      // (اختياري) يمكنك إضافة منطق لإظهار رصاصة الخصم هنا في المستقبل
      print("خصم أطلق النار من: ${data['x']}, ${data['y']}");
    });
  }

  // الانضمام إلى غرفة
  void joinRoom(String roomId, String name) {
    _roomId = roomId;
    _playerName = name;
    socket.emit('join_room', {'roomId': roomId, 'playerName': name});
    
    // حفظ الـ ID الخاص بي القادم من الخادم
    socket.on('connect', (_) {
      _playerId = socket.id;
    });
  }

  // إرسال حركتي للخادم (كي يراها الأصدقاء)
  void sendPosition(double x, double y) {
    if (_roomId != null && _playerId != null) {
      socket.emit('update_position', {
        'roomId': _roomId,
        'playerId': _playerId,
        'x': x,
        'y': y,
      });
    }
  }

  // إرسال إطلاق النار
  void sendShoot(double x, double y, double dx, double dy) {
    if (_roomId != null) {
      socket.emit('player_shoot', {
        'roomId': _roomId,
        'x': x,
        'y': y,
        'dx': dx,
        'dy': dy,
      });
    }
  }

  // عند إغلاق التطبيق
  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }
}
