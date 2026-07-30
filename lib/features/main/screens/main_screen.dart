import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_offline_banner.dart';
import '../../../core/widgets/app_confirm_exit.dart';
import '../../../core/widgets/tv_scaffold.dart';
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
