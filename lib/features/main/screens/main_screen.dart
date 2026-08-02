import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_offline_banner.dart';
import '../../../core/widgets/app_confirm_exit.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/services/websocket_service.dart';
import 'package:go_router/go_router.dart';
import '../widgets/idle_screen_manager.dart';

import 'package:flutter/services.dart';
import '../../../core/widgets/tv_drawer_menu.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final GlobalKey<TvDrawerMenuState> _drawerKey =
      GlobalKey<TvDrawerMenuState>();
  final FocusScopeNode _mainScreenFocusNode = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    _checkPairingStatus();
  }

  Future<void> _checkPairingStatus() async {
    try {
      final deviceService = ref.read(deviceServiceProvider);
      final deviceId = await deviceService.getDeviceId();
      final response = await deviceService.requestPairingCode();
      
      if (response['status'] != 'linked') {
        _handleUnpaired();
      } else {
        // Jika masih linked, dengarkan event unpaired secara real-time
        final wsService = ref.read(deviceWebSocketServiceProvider);
        wsService.connect(
          deviceId: deviceId,
          onPairingReceived: (id) {}, // Kita abaikan paired karena sudah di main
          onUnpairedReceived: () {
            _handleUnpaired();
          },
        );
      }
    } catch (_) {}
  }

  void _handleUnpaired() async {
    final storage = SecureStorageService();
    await storage.delete('selected_profil');
    ref.read(selectedProfilProvider.notifier).setProfil(null);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _mainScreenFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppConfirmExit(
      child: FocusScope(
        node: _mainScreenFocusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _drawerKey.currentState?.showDrawer();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TvScaffold(
          body: Stack(
            children: [
              Column(
                children: const [
                  IdleScreenManager(),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppOfflineBanner(
                  isDot: true,
                  onRetry: () {},
                ),
              ),
              TvDrawerMenu(
                key: _drawerKey,
                onDrawerClosed: () {
                  _mainScreenFocusNode.requestFocus();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
