import 'package:flutter/material.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppTopBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(32.0),
        children: [
          _buildSettingsItem(Icons.wifi, 'Koneksi Jaringan', 'Terhubung ke WiFi (Dummy)'),
          _buildSettingsItem(Icons.color_lens, 'Tema Aplikasi', 'Terang (Dummy)'),
          _buildSettingsItem(Icons.language, 'Bahasa', 'Indonesia (Dummy)'),
          _buildSettingsItem(Icons.update, 'Pembaruan Perangkat Lunak', 'Versi 1.0.0 (Terbaru)'),
          _buildSettingsItem(Icons.info_outline, 'Tentang Aplikasi', 'Jadwal Sholat Kominfo Pekanbaru'),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          focusColor: AppColors.primary.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(icon, size: 40, color: AppColors.primary),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 40, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
