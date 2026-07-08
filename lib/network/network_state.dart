class NetworkState {
  final bool isHost;
  final bool isConnected;
  final bool isReady;
  final String? roomId;
  final String? localName;
  final String? remoteName;
  final String? lastError;

  const NetworkState({
    required this.isHost,
    required this.isConnected,
    required this.isReady,
    this.roomId,
    this.localName,
    this.remoteName,
    this.lastError,
  });

  NetworkState copyWith({
    bool? isHost,
    bool? isConnected,
    bool? isReady,
    String? roomId,
    String? localName,
    String? remoteName,
    String? lastError,
  }) {
    return NetworkState(
      isHost: isHost ?? this.isHost,
      isConnected: isConnected ?? this.isConnected,
      isReady: isReady ?? this.isReady,
      roomId: roomId ?? this.roomId,
      localName: localName ?? this.localName,
      remoteName: remoteName ?? this.remoteName,
      lastError: lastError ?? this.lastError,
    );
  }

  factory NetworkState.initial() {
    return const NetworkState(
      isHost: false,
      isConnected: false,
      isReady: false,
    );
  }
}
