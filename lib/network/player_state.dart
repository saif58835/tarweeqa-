class PlayerState {
  final String id;
  final String name;
  final double x;
  final double y;
  final int health;
  final int score;
  final bool isAlive;

  const PlayerState({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.health,
    required this.score,
    required this.isAlive,
  });

  PlayerState copyWith({
    String? id,
    String? name,
    double? x,
    double? y,
    int? health,
    int? score,
    bool? isAlive,
  }) {
    return PlayerState(
      id: id ?? this.id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      health: health ?? this.health,
      score: score ?? this.score,
      isAlive: isAlive ?? this.isAlive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'x': x,
      'y': y,
      'health': health,
      'score': score,
      'isAlive': isAlive,
    };
  }

  factory PlayerState.fromMap(Map<String, dynamic> map) {
    return PlayerState(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      x: (map['x'] ?? 0).toDouble(),
      y: (map['y'] ?? 0).toDouble(),
      health: map['health'] ?? 3,
      score: map['score'] ?? 0,
      isAlive: map['isAlive'] ?? true,
    );
  }
}
