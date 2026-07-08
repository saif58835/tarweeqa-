import 'dart:async';
import 'network_manager.dart';
import 'network_messages.dart';
import 'player_state.dart';
import 'room_model.dart';

class NetworkService {
  late final NetworkManager _manager;

  RoomModel? room;
  PlayerState? localPlayer;
  PlayerState? remotePlayer;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  NetworkService() {
    _manager = NetworkManager(
      onMessage: _handleMessage,
      onConnected: () {},
      onError: (error) {},
      onDisconnected: () {},
    );
  }

  void _handleMessage(Map<String, dynamic> data) {
    _messageController.add(data);
  }

  Future<void> host({
    required String name,
    required String roomId,
    required int port,
  }) async {
    room = RoomModel(roomId: roomId, hostName: name, isActive: false);
    localPlayer = PlayerState(
      id: 'host',
      name: name,
      x: 100,
      y: 100,
      health: 3,
      score: 0,
      isAlive: true,
    );
    await _manager.host(port: port);
  }

  Future<void> join({
    required String name,
    required String roomId,
    required String ip,
    required int port,
  }) async {
    room = RoomModel(
      roomId: roomId,
      hostName: '',
      joinName: name,
      isActive: false,
    );
    localPlayer = PlayerState(
      id: 'join',
      name: name,
      x: 200,
      y: 100,
      health: 3,
      score: 0,
      isAlive: true,
    );
    await _manager.join(ip: ip, port: port);
  }

  void sendJoin() {
    if (localPlayer == null) return;
    _manager.send(
      NetworkMessages.join(
        name: localPlayer!.name,
        role: localPlayer!.id,
      ),
    );
  }

  void sendState(PlayerState state) {
    _manager.send(
      NetworkMessages.state(
        x: state.x,
        y: state.y,
        health: state.health,
        score: state.score,
      ),
    );
  }

  void sendShoot({
    required double x,
    required double y,
    required double dx,
    required double dy,
  }) {
    _manager.send(NetworkMessages.shoot(x: x, y: y, dx: dx, dy: dy));
  }

  void sendGameOver(String winner) {
    _manager.send(NetworkMessages.gameOver(winner: winner));
  }

  Future<void> disconnect() async {
    await _manager.disconnect();
    await _messageController.close();
  }
}
