import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

class TvDrawerMenu extends StatefulWidget {
  final VoidCallback onDrawerClosed;

  const TvDrawerMenu({super.key, required this.onDrawerClosed});

  @override
  State<TvDrawerMenu> createState() => TvDrawerMenuState();
}

class TvDrawerMenuState extends State<TvDrawerMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  Timer? _hideTimer;

  final FocusNode _drawerWrapperFocusNode = FocusNode();
  final FocusNode _gantiProfilFocusNode = FocusNode();
  final FocusNode _settingsFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Masuk dari kiri (sumbu X)
    _offsetAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mulanya tertutup
    });

    // Cegah fokus melompat keluar dari laci (menghilang ke ruang hampa)
    _gantiProfilFocusNode.onKeyEvent = (node, event) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };

    _settingsFocusNode.onKeyEvent = (node, event) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  void showDrawer() {
    _animationController.forward();
    _startHideTimer();
    _gantiProfilFocusNode.requestFocus();
  }

  void hideDrawer() {
    _hideTimer?.cancel();
    _animationController.reverse();
    widget.onDrawerClosed();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        hideDrawer();
      }
    });
  }

  void _onFocusChanged(bool _) {
    final isFocused =
        _gantiProfilFocusNode.hasFocus ||
        _settingsFocusNode.hasFocus ||
        _drawerWrapperFocusNode.hasFocus;

    // Auto-dismiss jika dibiarkan (meskipun sedang fokus)
    if (isFocused) {
      _startHideTimer();
    }
  }

  void _handlePressProfil() {
    hideDrawer();
    context.pushNamed('select_profil');
  }

  void _handlePressSettings() {
    hideDrawer();
    context.pushNamed('settings');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hideTimer?.cancel();
    _drawerWrapperFocusNode.dispose();
    _gantiProfilFocusNode.dispose();
    _settingsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ExcludeFocus(
            excluding: _animationController.isDismissed,
            child: child!,
          );
        },
        child: Focus(
          focusNode: _drawerWrapperFocusNode,
          onKeyEvent: (node, event) {
            // Tangkap D-Pad Kiri untuk menutup drawer
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              hideDrawer();
              return KeyEventResult.handled;
            }

            // Jika ada input tombol lain, reset timer agar tidak tiba-tiba tertutup saat user sedang aktif navigasi
            if (event is KeyDownEvent) {
              _startHideTimer();
            }

            return KeyEventResult.ignored;
          },
          child: Container(
            width: 450,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: SafeArea(
              child: FocusTraversalGroup(
                policy: WidgetOrderTraversalPolicy(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 64),
                    Center(
                      child: Image.asset(
                        'assets/logo/logo-pemko-kominfo.webp',
                        width: 250,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Center(
                      child: Text(
                        'JWS Diskominfo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    _TvDrawerMenuItem(
                      focusNode: _gantiProfilFocusNode,
                      onFocusChange: _onFocusChanged,
                      onPressed: _handlePressProfil,
                      icon: Icons.swap_horiz,
                      label: 'Ganti Profil',
                    ),
                    _TvDrawerMenuItem(
                      focusNode: _settingsFocusNode,
                      onFocusChange: _onFocusChanged,
                      onPressed: _handlePressSettings,
                      icon: Icons.settings,
                      label: 'Pengaturan',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TvDrawerMenuItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;

  const _TvDrawerMenuItem({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.focusNode,
    this.onFocusChange,
  });

  @override
  State<_TvDrawerMenuItem> createState() => _TvDrawerMenuItemState();
}

class _TvDrawerMenuItemState extends State<_TvDrawerMenuItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        focusNode: widget.focusNode,
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
          if (widget.onFocusChange != null) {
            widget.onFocusChange!(hasFocus);
          }
        },
        onTap: widget.onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
          decoration: BoxDecoration(
            color: _isFocused ? Colors.blue.shade600 : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: _isFocused ? Colors.white : Colors.transparent,
                width: 6,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: _isFocused ? Colors.white : Colors.white70,
                size: 40,
              ),
              const SizedBox(width: 24),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isFocused ? Colors.white : Colors.white70,
                  fontSize: 28,
                  fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
