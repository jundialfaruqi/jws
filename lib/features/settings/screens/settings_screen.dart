import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Satu fokus utama yang memonopoli input seluruh layar
  final FocusNode _mainFocusNode = FocusNode(debugLabel: 'SettingsMainFocus');
  int _selectedIndex = 0;
  final int _itemCount = 5;
  late final List<GlobalKey> _itemKeys;

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(_itemCount, (_) => GlobalKey());
    
    // Minta fokus ke root node begitu layar terbuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_mainFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _mainFocusNode.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    final context = _itemKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
      );
    }
  }

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
        focusNode: _mainFocusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (_selectedIndex < _itemCount - 1) {
                setState(() {
                  _selectedIndex++;
                });
                _scrollToIndex(_selectedIndex);
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (_selectedIndex > 0) {
                setState(() {
                  _selectedIndex--;
                });
                _scrollToIndex(_selectedIndex);
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.enter || 
                       event.logicalKey == LogicalKeyboardKey.select) {
              debugPrint('Menu pengaturan index $_selectedIndex ditekan');
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored; // Biarkan tombol Back lewat
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              _buildSettingsItem(
                0,
                Icons.wifi,
                'Koneksi Jaringan',
                'Terhubung ke WiFi (Dummy)',
              ),
              _buildSettingsItem(
                1,
                Icons.color_lens,
                'Tema Aplikasi',
                'Terang (Dummy)',
              ),
              _buildSettingsItem(
                2, 
                Icons.language, 
                'Bahasa', 
                'Indonesia (Dummy)'
              ),
              _buildSettingsItem(
                3,
                Icons.update,
                'Pembaruan Perangkat Lunak',
                'Versi 1.0.0 (Terbaru)',
              ),
              _buildSettingsItem(
                4,
                Icons.info_outline,
                'Tentang Aplikasi',
                'Jadwal Sholat Kominfo Pekanbaru',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(int index, IconData icon, String title, String subtitle) {
    // Status visual sepenuhnya ditentukan dari perbandingan index
    final isFocused = _selectedIndex == index;

    return Padding(
      key: _itemKeys[index],
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: isFocused ? AppColors.ghost : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: isFocused ? AppColors.primary : Colors.grey.shade600,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isFocused ? AppColors.primary : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
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
                color: isFocused ? AppColors.primary : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
