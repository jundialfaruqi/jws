import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import '../../features/main/providers/my_masjid_provider.dart';

final webSocketServiceProvider = Provider.family<WebSocketService, int>((ref, id) {
  final service = WebSocketService(ref: ref, id: id);
  ref.onDispose(() {
    service.disconnect();
  });
  return service;
});

final deviceWebSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService(ref: ref, id: 0);
  ref.onDispose(() {
    service.disconnect();
  });
  return service;
});

class WebSocketService {
  final Ref ref;
  final int id;
  PusherChannelsClient? _pusherClient;
  bool _isConnected = false;
  StreamSubscription? _connectionSub;

  WebSocketService({required this.ref, required this.id});

  bool get isConnected => _isConnected;

  Future<void> connect({
    String? deviceId,
    Function(int masjidId)? onPairingReceived,
    Function()? onUnpairedReceived,
  }) async {
    if (_isConnected) return;

    try {
      final apiKey = dotenv.env['REVERB_APP_KEY'] ?? '';
      final host = dotenv.env['REVERB_HOST'] ?? '127.0.0.1';
      final port = int.tryParse(dotenv.env['REVERB_PORT'] ?? '8080') ?? 8080;
      final scheme = dotenv.env['REVERB_SCHEME'] ?? 'http';
      final baseUrl = dotenv.env['BASE_URL'] ?? 'http://127.0.0.1:8000/';

      final wsScheme = scheme == 'https' ? 'wss' : 'ws';

      // URL auth endpoint kustom untuk TV (tanpa login email/password)
      final authUrl = '${baseUrl}api/v2/device/broadcasting/auth';

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
          Future.delayed(const Duration(seconds: 5), () {
            refresh();
          });
        },
      );

      _connectionSub = _pusherClient!.onConnectionEstablished.listen((_) {
        _isConnected = true;
        
        if (deviceId != null) {
          debugPrint("WebSocket Subscribed to presence-device-$deviceId at $wsScheme://$host:$port");

          // Gunakan Presence Channel agar admin bisa melihat status online/offline TV
          final channel = _pusherClient!.presenceChannel(
            'presence-device-$deviceId',
            authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate.forPresenceChannel(
              authorizationEndpoint: Uri.parse(authUrl),
              headers: {'X-Device-ID': deviceId},
            ),
          );
          channel.subscribe();

          channel.bind('device.paired').listen((event) {
            debugPrint("WebSocket Event Received: device.paired");
            if (event.data != null) {
               try {
                 final map = event.data is String ? jsonDecode(event.data) : event.data;
                 if (map != null && map['masjid_id'] != null && onPairingReceived != null) {
                   onPairingReceived(int.parse(map['masjid_id'].toString()));
                 }
               } catch (e) {
                 debugPrint("Error parsing device.paired payload: $e");
               }
            }
          });
          
          channel.bind('device.unpaired').listen((event) {
            debugPrint("WebSocket Event Received: device.unpaired");
            if (onUnpairedReceived != null) {
              onUnpairedReceived();
            }
          });
        } else {
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
        }
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
      _pusherClient = null;
      debugPrint("WebSocket Disconnected");
    } catch (e) {
      debugPrint("WebSocket Disconnect Error: $e");
    }
  }

  /// Memutus koneksi lama lalu menghubungkan ulang dengan callback baru.
  /// Gunakan ini saat PairingScreen perlu mendengar event paired setelah di-kick dari MainScreen.
  Future<void> reconnect({
    String? deviceId,
    Function(int masjidId)? onPairingReceived,
    Function()? onUnpairedReceived,
  }) async {
    await disconnect();
    await connect(
      deviceId: deviceId,
      onPairingReceived: onPairingReceived,
      onUnpairedReceived: onUnpairedReceived,
    );
  }
}
