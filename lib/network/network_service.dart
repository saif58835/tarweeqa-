import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';

class NetworkService extends ChangeNotifier {
  late IO.Socket socket;

  String? _roomId;
  String? _playerId;
  String? _playerName;

  List<Map<String, dynamic>> playersInRoom = [];

  bool get isConnected => socket.connected;


  // الاتصال بالخادم
  void connectToServer(String serverUrl) {
    socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );


    socket.connect();


    socket.onConnect((_) {
      _playerId = socket.id;
      print("متصل بالخادم: $_playerId");
    });


    // تحديث اللاعبين
    socket.on('update_players', (data) {

      playersInRoom =
          List<Map<String, dynamic>>.from(data);

      playersInRoom.removeWhere(
        (player) => player['id'] == _playerId,
      );

      notifyListeners();
    });


    // حركة الخصم
    socket.on('opponent_moved', (data) {

      final index = playersInRoom.indexWhere(
        (p) => p['id'] == data['playerId'],
      );


      if (index != -1) {

        playersInRoom[index]['x'] = data['x'];
        playersInRoom[index]['y'] = data['y'];

        notifyListeners();
      }
    });



    // إطلاق نار الخصم
    socket.on('opponent_shoot', (data) {

      print(
        "خصم أطلق النار من: ${data['x']} , ${data['y']}",
      );

    });


    socket.onDisconnect((_) {
      print("انقطع الاتصال");
    });
  }



  // دخول غرفة
  void joinRoom(String roomId, String name) {

    _roomId = roomId;
    _playerName = name;


    if (socket.connected) {

      socket.emit(
        'join_room',
        {
          'roomId': roomId,
          'playerName': name,
        },
      );

    } else {

      socket.onConnect((_) {

        socket.emit(
          'join_room',
          {
            'roomId': roomId,
            'playerName': name,
          },
        );

      });
    }
  }




  // إرسال الموقع
  void sendPosition(double x, double y) {

    if (_roomId != null &&
        _playerId != null) {

      socket.emit(
        'update_position',
        {
          'roomId': _roomId,
          'playerId': _playerId,
          'x': x,
          'y': y,
        },
      );

    }
  }




  // إطلاق النار
  void sendShoot(
      double x,
      double y,
      double dx,
      double dy,
      ) {

    if (_roomId != null) {

      socket.emit(
        'player_shoot',
        {
          'roomId': _roomId,
          'x': x,
          'y': y,
          'dx': dx,
          'dy': dy,
        },
      );

    }
  }




  @override
  void dispose() {

    if (socket.connected) {
      socket.dispose();
    }

    super.dispose();
  }
}
