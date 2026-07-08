class RoomModel {
  final String roomId;
  final String hostName;
  final String? joinName;
  final bool isActive;
  final String? winner;
  final int hostScore;
  final int joinScore;

  const RoomModel({
    required this.roomId,
    required this.hostName,
    this.joinName,
    this.isActive = false,
    this.winner,
    this.hostScore = 0,
    this.joinScore = 0,
  });

  RoomModel copyWith({
    String? roomId,
    String? hostName,
    String? joinName,
    bool? isActive,
    String? winner,
    int? hostScore,
    int? joinScore,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      hostName: hostName ?? this.hostName,
      joinName: joinName ?? this.joinName,
      isActive: isActive ?? this.isActive,
      winner: winner ?? this.winner,
      hostScore: hostScore ?? this.hostScore,
      joinScore: joinScore ?? this.joinScore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'hostName': hostName,
      'joinName': joinName,
      'isActive': isActive,
      'winner': winner,
      'hostScore': hostScore,
      'joinScore': joinScore,
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      roomId: map['roomId'] ?? '',
      hostName: map['hostName'] ?? '',
      joinName: map['joinName'],
      isActive: map['isActive'] ?? false,
      winner: map['winner'],
      hostScore: map['hostScore'] ?? 0,
      joinScore: map['joinScore'] ?? 0,
    );
  }
}
