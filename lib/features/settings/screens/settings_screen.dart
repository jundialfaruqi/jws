import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/app_view_selection_dialog.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/view_mode_provider.dart';
import '../../../core/providers/selected_profil_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      appBar: AppTopBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(32.0),
        children: [
          _SettingsItemWidget(
            icon: Icons.launch,
            title: 'Izin Layar Mengambang (Auto-Start)',
            subtitle: 'Wajib diaktifkan untuk Auto-Start (Khusus Android 10+)',
            onTap: () async {
              const platform = MethodChannel('id.go.pekanbaru.jws/settings');
              try {
                await platform.invokeMethod('openOverlaySettings');
              } catch (e) {
                debugPrint("Gagal membuka pengaturan: $e");
              }
            },
          ),
          _SettingsItemWidget(
            icon: Icons.tv,
            title: 'Mode Tampilan JWS',
            subtitle: 'Pilih antara versi Web atau Aplikasi Native',
            onTap: () {
              AppViewSelectionDialog.show(
                context,
                title: 'Ubah Mode Tampilan',
                subtitle: 'Apakah Anda ingin beralih tampilan?',
                onPrimarySelected: () async {
                  await ref
                      .read(viewModeProvider.notifier)
                      .setViewMode('native');
                  if (context.mounted) context.goNamed('main');
                },
                onSecondarySelected: () async {
                  await ref.read(viewModeProvider.notifier).setViewMode('web');
                  if (context.mounted) {
                    final profil = ref.read(selectedProfilProvider);
                    if (profil != null) {
                      context.goNamed(
                        'webview',
                        pathParameters: {'slug': profil.slug},
                      );
                    }
                  }
                },
              );
            },
          ),
          _SettingsItemWidget(
            icon: Icons.notifications_active,
            title: 'Simulasi Layar Adzan (Debug)',
            subtitle: 'Tekan untuk melihat preview layar saat adzan berkumandang',
            onTap: () {
              if (context.mounted) context.pushNamed('adzan');
            },
          ),
          _SettingsItemWidget(
            icon: Icons.timer,
            title: 'Simulasi Layar Iqomah (Debug)',
            subtitle: 'Tekan untuk melihat preview layar hitung mundur Iqomah',
            onTap: () {
              if (context.mounted) context.pushNamed('iqomah');
            },
          ),
          _SettingsItemWidget(
            icon: Icons.do_not_disturb_on,
            title: 'Simulasi Layar Sholat (Debug)',
            subtitle: 'Tekan untuk melihat preview layar saat sholat berlangsung',
            onTap: () {
              if (context.mounted) context.pushNamed('final');
            },
          ),
          _SettingsItemWidget(
            icon: Icons.menu_book,
            title: 'Simulasi Layar Jumat (Debug)',
            subtitle: 'Tekan untuk melihat preview layar saat Khutbah Jumat',
            onTap: () {
              if (context.mounted) context.pushNamed('jumat');
            },
          ),
          _SettingsItemWidget(
            icon: Icons.mosque,
            title: 'Simulasi Jumbotron Masjid (Debug)',
            subtitle: 'Tekan untuk melihat preview Splash/Jumbotron Logo Masjid',
            onTap: () {
              if (context.mounted) context.pushNamed('jumbotron-masjid');
            },
          ),
          _SettingsItemWidget(
            icon: Icons.account_balance,
            title: 'Simulasi Jumbotron Pemko (Debug)',
            subtitle: 'Tekan untuk melihat preview Splash/Jumbotron Logo Pemko',
            onTap: () {
              if (context.mounted) context.pushNamed('jumbotron-pemko');
            },
          ),
        ],
      ),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
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
