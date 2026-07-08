import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NetworkManager {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final void Function(Map<String, dynamic> data)? onMessage;
  final void Function()? onConnected;
  final void Function(String error)? onError;
  final void Function()? onDisconnected;

  NetworkManager({
    this.onMessage,
    this.onConnected,
    this.onError,
    this.onDisconnected,
  });

  bool get isConnected => _channel != null;

  Future<void> host({required int port}) async {
    try {
      final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      onConnected?.call();

      await for (final request in server) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          _channel = IOWebSocketChannel(socket);

          _subscription = _channel!.stream.listen(
            (event) {
              final data = jsonDecode(event as String) as Map<String, dynamic>;
              onMessage?.call(data);
            },
            onError: (e) => onError?.call(e.toString()),
            onDone: () => onDisconnected?.call(),
          );
        } else {
          request.response
            ..statusCode = HttpStatus.forbidden
            ..write('WebSocket only')
            ..close();
        }
      }
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  Future<void> join({required String ip, required int port}) async {
    try {
      _channel = IOWebSocketChannel.connect('ws://$ip:$port');

      _subscription = _channel!.stream.listen(
        (event) {
          final data = jsonDecode(event as String) as Map<String, dynamic>;
          onMessage?.call(data);
        },
        onError: (e) => onError?.call(e.toString()),
        onDone: () => onDisconnected?.call(),
      );

      onConnected?.call();
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  void send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
    onDisconnected?.call();
  }
}
