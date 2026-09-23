import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/network/api_client.dart';

/// اتصال آني بالخادم للرسائل والإشعارات الفورية (3.7).
///
/// تُستعمل Streams بدل ValueNotifier: الأخير لا يُشعر المستمعين إن
/// كانت القيمة الجديدة مطابقة للسابقة، فتضيع رسالة مكرّرة.
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;

  final _messageCtrl = StreamController<SocketMessage>.broadcast();
  final _notificationCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _typingCtrl = StreamController<TypingEvent>.broadcast();

  /// رسالة جديدة وصلت من الطرف الآخر
  Stream<SocketMessage> get messages => _messageCtrl.stream;

  /// إشعار جديد
  Stream<Map<String, dynamic>> get notifications => _notificationCtrl.stream;

  /// الطرف الآخر يكتب الآن
  Stream<TypingEvent> get typing => _typingCtrl.stream;

  /// حالة الاتصال — تُستعمل لعرض «غير متّصل» في الواجهة
  final ValueNotifier<bool> connected = ValueNotifier(false);

  String? _token;

  void connect(String token) {
    // إعادة الاتصال بنفس الرمز لا تستدعي إعادة البناء
    if (_socket != null && _token == token && (_socket?.connected ?? false)) {
      return;
    }
    _token = token;
    _disposeSocket();

    _socket = io.io(
      ApiClient.baseUrl,
      io.OptionBuilder()
          // نسمح بـ polling كبديل: بعض الاستضافات (Render مثلًا) تحتاج
          // التفاوض عبر polling قبل الترقية إلى websocket.
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(9999)
          .setReconnectionDelay(1500)
          .setReconnectionDelayMax(8000)
          .enableForceNew()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        connected.value = true;
        debugPrint('[socket] متّصل');
      })
      ..onDisconnect((_) {
        connected.value = false;
        debugPrint('[socket] انقطع الاتصال');
      })
      ..onReconnect((_) => debugPrint('[socket] أُعيد الاتصال'))
      ..on('message:new', (data) {
        if (data is! Map) return;
        final map = Map<String, dynamic>.from(data);
        final raw = map['message'];
        if (raw is! Map) return;

        _messageCtrl.add(SocketMessage(
          conversationId: '${map['conversationId']}',
          message: Map<String, dynamic>.from(raw),
        ));
      })
      ..on('notification', (data) {
        if (data is Map) {
          _notificationCtrl.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('typing', (data) {
        if (data is! Map) return;
        _typingCtrl.add(TypingEvent(
          conversationId: '${data['conversationId']}',
          from: '${data['from']}',
        ));
      })
      ..onConnectError((e) {
        connected.value = false;
        debugPrint('[socket] خطأ اتصال: $e');
      })
      ..onError((e) => debugPrint('[socket] خطأ: $e'));
  }

  void emitTyping(String conversationId, String to) {
    _socket?.emit('typing', {'conversationId': conversationId, 'to': to});
  }

  void _disposeSocket() {
    _socket?.dispose();
    _socket = null;
    connected.value = false;
  }

  void disconnect() {
    _token = null;
    _disposeSocket();
  }
}

/// رسالة واردة عبر المقبس
class SocketMessage {
  final String conversationId;
  final Map<String, dynamic> message;

  const SocketMessage({required this.conversationId, required this.message});
}

/// إشعار «يكتب الآن»
class TypingEvent {
  final String conversationId;
  final String from;

  const TypingEvent({required this.conversationId, required this.from});
}
