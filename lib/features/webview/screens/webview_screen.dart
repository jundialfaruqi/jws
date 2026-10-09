import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/widgets/app_loading_spinner.dart';
import '../../../core/widgets/tv_drawer_menu.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/widgets/app_confirm_exit.dart';

class WebViewScreen extends StatefulWidget {
  final String slug;

  const WebViewScreen({super.key, required this.slug});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  
  final GlobalKey<TvDrawerMenuState> _drawerKey = GlobalKey<TvDrawerMenuState>();
  final FocusNode _screenFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Asumsi URL menggunakan format Laravel standar untuk masjid
    final url = 'https://jadwalsholat.pekanbaru.go.id/${widget.slug}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  void dispose() {
    _screenFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppConfirmExit(
      child: Focus(
        focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _drawerKey.currentState?.showDrawer();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TvScaffold(
        backgroundColor: Colors.black,
        body: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                const Center(
                  child: AppLoadingSpinner(message: 'Memuat Web View...'),
                ),
            // TvDrawerMenu yang sama dengan MainScreen
            TvDrawerMenu(
              key: _drawerKey,
              onDrawerClosed: () {
                _screenFocusNode.requestFocus();
              },
            ),
          ],
        ),
      ),
    ),
    );
  }
}
