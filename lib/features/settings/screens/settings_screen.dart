import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppTopBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.down);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.up);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: Column(
            children: [
              _buildSettingsItem(
                Icons.wifi,
                'Koneksi Jaringan',
                'Terhubung ke WiFi (Dummy)',
              ),
              _buildSettingsItem(
                Icons.color_lens,
                'Tema Aplikasi',
                'Terang (Dummy)',
              ),
              _buildSettingsItem(Icons.language, 'Bahasa', 'Indonesia (Dummy)'),
              _buildSettingsItem(
                Icons.update,
                'Pembaruan Perangkat Lunak',
                'Versi 1.0.0 (Terbaru)',
              ),
              _buildSettingsItem(
                Icons.info_outline,
                'Tentang Aplikasi',
                'Jadwal Sholat Kominfo Pekanbaru',
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle) {
    return _SettingsItemWidget(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () {},
    );
  }
}

class _SettingsItemWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItemWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_SettingsItemWidget> createState() => _SettingsItemWidgetState();
}

class _SettingsItemWidgetState extends State<_SettingsItemWidget> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: _isFocused ? AppColors.ghost : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          onFocusChange: (hasFocus) {
            setState(() {
              _isFocused = hasFocus;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 40,
                  color: _isFocused ? AppColors.primary : Colors.grey.shade600,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _isFocused
                              ? AppColors.primary
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 40,
                  color: _isFocused ? AppColors.primary : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
