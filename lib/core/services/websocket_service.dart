import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import '../../features/main/providers/my_masjid_provider.dart';

final webSocketServiceProvider = Provider.family<WebSocketService, int>((ref, id) {
  final service = WebSocketService(ref: ref, id: id);
  ref.onDispose(() {
    service.disconnect();
  });
  return service;
});

class WebSocketService {
  final Ref ref;
  final int id;
  PusherChannelsClient? _pusherClient;
  StreamSubscription? _connectionSub;
  bool _isConnected = false;

  WebSocketService({required this.ref, required this.id});

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final apiKey = dotenv.env['REVERB_APP_KEY'] ?? '';
      final host = dotenv.env['REVERB_HOST'] ?? '127.0.0.1';
      final port = int.tryParse(dotenv.env['REVERB_PORT'] ?? '8080') ?? 8080;
      final scheme = dotenv.env['REVERB_SCHEME'] ?? 'http';

      final wsScheme = scheme == 'https' ? 'wss' : 'ws';

      final options = PusherChannelsOptions.fromHost(
        scheme: wsScheme,
        host: host,
        port: port,
        key: apiKey,
      );

      _pusherClient = PusherChannelsClient.websocket(
        options: options,
        connectionErrorHandler: (error, trace, refresh) {
          debugPrint("WebSocket Error: $error");
          refresh();
        },
      );

      _connectionSub = _pusherClient!.onConnectionEstablished.listen((_) {
        _isConnected = true;
        debugPrint("WebSocket Subscribed to masjid-$id at $wsScheme://$host:$port");
        
        final channel = _pusherClient!.publicChannel('masjid-$id');
        channel.subscribe();

        channel.bind('App\\Events\\ContentUpdatedEvent').listen((event) {
          debugPrint("WebSocket Event Received: ContentUpdatedEvent");
          debugPrint("Triggering Data Refresh...");
          ref.invalidate(myMasjidProvider(id));
        });

        // Channel Global (Jumbotron Pemko, Marquee Global, dll)
        final globalChannel = _pusherClient!.publicChannel('global-masjid');
        globalChannel.subscribe();

        globalChannel.bind('App\\Events\\GlobalUpdatedEvent').listen((event) {
          debugPrint("WebSocket Event Received: GlobalUpdatedEvent");
          debugPrint("Triggering Data Refresh...");
          ref.invalidate(myMasjidProvider(id));
        });
      });

      _pusherClient!.connect();

    } catch (e) {
      debugPrint("WebSocket Connection Failed: $e");
    }
  }

  Future<void> disconnect() async {
    if (!_isConnected || _pusherClient == null) return;
    try {
      _connectionSub?.cancel();
      _pusherClient!.disconnect();
      _isConnected = false;
      debugPrint("WebSocket Disconnected");
    } catch (e) {
      debugPrint("WebSocket Disconnect Error: $e");
    }
  }
}

