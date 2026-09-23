import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/network/api_client.dart';

/// اتصال آني بالخادم للرسائل والإشعارات الفورية (3.7)
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;

  final ValueNotifier<Map<String, dynamic>?> onNotification =
      ValueNotifier(null);
  final ValueNotifier<Map<String, dynamic>?> onMessage = ValueNotifier(null);
  final ValueNotifier<bool> connected = ValueNotifier(false);

  void connect(String token) {
    disconnect();

    _socket = io.io(
      ApiClient.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!
      ..onConnect((_) => connected.value = true)
      ..onDisconnect((_) => connected.value = false)
      ..on('notification', (data) {
        if (data is Map) onNotification.value = Map<String, dynamic>.from(data);
      })
      ..on('message:new', (data) {
        if (data is Map) onMessage.value = Map<String, dynamic>.from(data);
      })
      ..onConnectError((e) => debugPrint('[socket] خطأ اتصال: $e'));
  }

  void emitTyping(String conversationId, String to) {
    _socket?.emit('typing', {'conversationId': conversationId, 'to': to});
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    connected.value = false;
  }
}
