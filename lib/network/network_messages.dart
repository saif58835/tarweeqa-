class NetworkMessages {
  static const String typeJoin = 'join';
  static const String typeStart = 'start';
  static const String typeState = 'state';
  static const String typeShoot = 'shoot';
  static const String typeHit = 'hit';
  static const String typeGameOver = 'game_over';
  static const String typePing = 'ping';

  static Map<String, dynamic> join({
    required String name,
    required String role,
  }) {
    return {
      'type': typeJoin,
      'name': name,
      'role': role,
    };
  }

  static Map<String, dynamic> start({
    required String roomId,
  }) {
    return {
      'type': typeStart,
      'roomId': roomId,
    };
  }

  static Map<String, dynamic> state({
    required double x,
    required double y,
    required int health,
    required int score,
  }) {
    return {
      'type': typeState,
      'x': x,
      'y': y,
      'health': health,
      'score': score,
    };
  }

  static Map<String, dynamic> shoot({
    required double x,
    required double y,
    required double dx,
    required double dy,
  }) {
    return {
      'type': typeShoot,
      'x': x,
      'y': y,
      'dx': dx,
      'dy': dy,
    };
  }

  static Map<String, dynamic> hit({
    required int damage,
  }) {
    return {
      'type': typeHit,
      'damage': damage,
    };
  }

  static Map<String, dynamic> gameOver({
    required String winner,
  }) {
    return {
      'type': typeGameOver,
      'winner': winner,
    };
  }

  static Map<String, dynamic> ping() {
    return {
      'type': typePing,
      'time': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
