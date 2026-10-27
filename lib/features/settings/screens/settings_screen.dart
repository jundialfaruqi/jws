import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/app_view_selection_dialog.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/view_mode_provider.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/providers/audio_settings_provider.dart';
import '../../../core/time/time_sync_service.dart';
import '../../main/providers/my_masjid_provider.dart';
import '../../main/models/jadwal_sholat_model.dart';

import '../../../core/services/device_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/widgets/tv/tv_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioSettings = ref.watch(audioSettingsProvider);
    final selectedProfil = ref.watch(selectedProfilProvider);

    return AppScaffold(
      appBar: AppTopBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32.0, 32.0, 32.0, 120.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          _SettingsItemWidget(
            icon: Icons.volume_off,
            title: 'Bisukan Suara Adzan',
            subtitle:
                'Jika diaktifkan, suara Adzan tidak akan diputar saat masuk waktu sholat.',
            trailing: Switch(
              value: audioSettings.isAdzanMuted,
              onChanged: (val) {
                ref.read(audioSettingsProvider.notifier).toggleAdzanMuted();
              },
            ),
            onTap: () {
              ref.read(audioSettingsProvider.notifier).toggleAdzanMuted();
            },
          ),
          _SettingsItemWidget(
            icon: Icons.music_off,
            title: 'Bisukan Suara Murotal',
            subtitle:
                'Jika diaktifkan, suara Murotal tidak akan diputar sebagai latar belakang.',
            trailing: Switch(
              value: audioSettings.isMurotalMuted,
              onChanged: (val) {
                ref.read(audioSettingsProvider.notifier).toggleMurotalMuted();
              },
            ),
            onTap: () {
              ref.read(audioSettingsProvider.notifier).toggleMurotalMuted();
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
            icon: Icons.link_off,
            title: 'Putus Tautan TV / Pairing Ulang',
            subtitle: selectedProfil != null
                ? 'Terhubung ke: ${selectedProfil.name}. Putus tautan untuk memasangkan ke masjid lain.'
                : 'Hapus tautan perangkat TV ini dan kembali ke layar kode pairing.',
            iconColor: Colors.red.shade700,
            titleColor: Colors.red.shade700,
            onTap: () => _showUnpairConfirmation(context, ref),
          ),
          _SettingsItemWidget(
            icon: Icons.notifications_active,
            title: 'Simulasi Layar Adzan (Debug)',
            subtitle:
                'Tekan untuk melihat preview layar saat adzan berkumandang',
            onTap: () {
              if (context.mounted) context.pushNamed('adzan');
            },
          ),
          _SettingsItemWidget(
            icon: Icons.warning_amber_rounded,
            title: 'Simulasi Layar Peringatan Syuruq (Debug)',
            subtitle:
                'Tekan untuk melihat preview layar peringatan Syuruq',
            onTap: () {
              if (context.mounted) {
                context.pushNamed(
                  'alert',
                  queryParameters: {'preview': 'SYURUQ'},
                );
              }
            },
          ),
          _SettingsItemWidget(
            icon: Icons.wb_sunny_rounded,
            title: 'Simulasi Layar Dhuha (Debug)',
            subtitle:
                'Tekan untuk melihat preview layar peringatan waktu Dhuha',
            onTap: () {
              if (context.mounted) {
                context.pushNamed(
                  'alert',
                  queryParameters: {'preview': 'DHUHA'},
                );
              }
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
            title: 'Simulasi Layar Final (Debug)',
            subtitle:
                'Tekan untuk melihat preview layar saat sholat berlangsung',
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
            subtitle:
                'Tekan untuk melihat preview Splash/Jumbotron Logo Masjid',
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
          if (!kReleaseMode) ...[
            const SizedBox(height: 12),
            const _TimeSimulationControlWidget(),
          ],
        ],
        ),
      ),
    );
  }

  Future<void> _showUnpairConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final selectedProfil = ref.read(selectedProfilProvider);
    final masjidName = selectedProfil?.name ?? 'Masjid Saat Ini';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.link_off, color: Colors.red, size: 36),
            SizedBox(width: 16),
            Text(
              'Putus Tautan TV?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin memutuskan tautan TV ini dari "$masjidName"?\n\n'
          'Setelah diputus, TV akan kembali ke layar awal dan menampilkan kode pairing baru.',
          style: const TextStyle(
            fontSize: 20,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
        actions: [
          TvButton(
            label: 'Batal',
            variant: TvButtonVariant.ghost,
            autofocus: true,
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
          const SizedBox(width: 16),
          TvButton(
            label: 'Ya, Putus Tautan',
            variant: TvButtonVariant.danger,
            onPressed: () async {
              Navigator.of(dialogCtx).pop();

              if (!context.mounted) return;

              // Tampilkan dialog loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );

              try {
                // 1. Beritahu backend untuk unpair device ini
                await ref.read(deviceServiceProvider).unpairDevice();
              } catch (_) {}

              // 2. Reset device_id agar TV dipastikan mendapat kode pairing baru
              await ref.read(deviceServiceProvider).resetDeviceId();

              // 3. Hapus profil tersimpan di local storage
              final storage = SecureStorageService();
              await storage.delete('selected_profil');

              // 4. Reset state profil di riverpod
              ref.read(selectedProfilProvider.notifier).setProfil(null);

              // 4. Arahkan kembali ke halaman pairing ('/')
              if (context.mounted) {
                Navigator.of(context).pop(); // Tutup loading dialog
                context.go('/');
              }
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
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsItemWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  @override
  State<_SettingsItemWidget> createState() => _SettingsItemWidgetState();
}

class _SettingsItemWidgetState extends State<_SettingsItemWidget> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.titleColor ?? AppColors.primary;
    final activeIconColor =
        widget.iconColor ?? (widget.titleColor ?? AppColors.primary);

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
                color: _isFocused ? activeColor : Colors.transparent,
                width: 3,
              ),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 40,
                  color: _isFocused
                      ? activeIconColor
                      : (widget.iconColor ?? Colors.grey.shade600),
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
                              ? activeColor
                              : (widget.titleColor ?? Colors.black87),
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
                if (widget.trailing != null)
                  widget.trailing!
                else
                  Icon(
                    Icons.chevron_right,
                    size: 40,
                    color: _isFocused ? activeColor : Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeSimulationControlWidget extends ConsumerStatefulWidget {
  const _TimeSimulationControlWidget();

  @override
  ConsumerState<_TimeSimulationControlWidget> createState() =>
      _TimeSimulationControlWidgetState();
}

class _TimeSimulationControlWidgetState
    extends ConsumerState<_TimeSimulationControlWidget> {
  Timer? _timer;

  static const List<String> _hari = [
    '',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Ahad',
  ];

  static const List<String> _bulan = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatFullDate(DateTime dt) {
    final h = _hari[dt.weekday];
    final b = _bulan[dt.month];
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    final detik = dt.second.toString().padLeft(2, '0');
    return '$h, ${dt.day} $b ${dt.year}  •  $jam:$menit:$detik WIB';
  }

  String _formatOffset(Duration offset) {
    if (offset == Duration.zero) return 'Waktu Asli';
    final isAhead = !offset.isNegative;
    final abs = offset.abs();
    final d = abs.inDays;
    final h = abs.inHours % 24;
    final m = abs.inMinutes % 60;
    final s = abs.inSeconds % 60;

    final parts = <String>[];
    if (d > 0) parts.add('$d Hari');
    if (h > 0) parts.add('$h Jam');
    if (m > 0) parts.add('$m Menit');
    if (s > 0 || parts.isEmpty) parts.add('$s Detik');

    return '${isAhead ? '+' : '-'}${parts.join(' ')}';
  }

  void _jumpToPrayer(String prayerKey) {
    final timeService = ref.read(timeSyncServiceProvider);
    final current = timeService.now();
    final selectedProfil = ref.read(selectedProfilProvider);
    if (selectedProfil == null) return;
    final masjidData = ref.read(myMasjidProvider(selectedProfil.id)).value;
    if (masjidData == null || masjidData.jadwalSholat.isEmpty) return;

    final dateStr =
        "${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}";
    JadwalSholatModel? schedule;
    try {
      schedule = masjidData.jadwalSholat.firstWhere((j) => j.date == dateStr);
    } catch (_) {
      schedule = null;
    }
    if (schedule == null) return;

    String? timeStr;
    switch (prayerKey) {
      case 'IMSAK':
        timeStr = schedule.imsak;
        break;
      case 'SUBUH':
        timeStr = schedule.subuh;
        break;
      case 'SYURUQ':
        timeStr = schedule.terbit;
        break;
      case 'DHUHA':
        timeStr = schedule.dhuha;
        break;
      case 'DZUHUR':
        timeStr = schedule.dzuhur;
        break;
      case 'ASHAR':
        timeStr = schedule.ashar;
        break;
      case 'MAGHRIB':
        timeStr = schedule.maghrib;
        break;
      case 'ISYA':
        timeStr = schedule.isya;
        break;
    }
    if (timeStr == null || timeStr.length != 5) return;

    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    // Setel ke 30 detik sebelum jadwal agar transisi berjalan alami
    final target = DateTime(
      current.year,
      current.month,
      current.day,
      hour,
      minute,
      0,
    ).subtract(const Duration(seconds: 30));

    timeService.setTargetDateTime(target);
    if (mounted) setState(() {});
  }

  void _jumpToFriday() {
    final timeService = ref.read(timeSyncServiceProvider);
    final current = timeService.now();
    int daysUntilFriday = (DateTime.friday - current.weekday) % 7;
    if (daysUntilFriday == 0 &&
        (current.hour > 12 || (current.hour == 12 && current.minute > 30))) {
      daysUntilFriday = 7;
    }
    final targetDate = current.add(Duration(days: daysUntilFriday));
    final target = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      11,
      58,
      0,
    );
    timeService.setTargetDateTime(target);
    if (mounted) setState(() {});
  }

  Future<void> _pickDateTime() async {
    final timeService = ref.read(timeSyncServiceProvider);
    final current = timeService.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 2),
      lastDate: DateTime(current.year + 2),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (pickedTime == null || !mounted) return;

    final target = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
      0,
    );
    timeService.setTargetDateTime(target);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final timeService = ref.watch(timeSyncServiceProvider);
    final appNow = timeService.now();
    final realNow = timeService.realNow();
    final isSimulated = timeService.isSimulated;

    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 40),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Judul & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PENGATURAN WAKTU SIMULASI (DEBUG)',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Atur waktu aplikasi untuk menguji jadwal sholat, hari Jumat, dan alert transisi tanpa merubah jam sistem TV.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSimulated ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSimulated
                      ? 'STATUS: SIMULASI (${_formatOffset(timeService.simulationOffset)})'
                      : 'STATUS: WAKTU ASLI (NORMAL)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isSimulated ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tampilan Jam Aplikasi vs Waktu Nyata
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF94A3B8), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WAKTU APLIKASI (SIMULASI):',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatFullDate(appNow),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                ),
                const Text(
                  'WAKTU NYATA SISTEM:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFullDate(realNow),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Bagian 1: Lompat Cepat ke Jadwal Sholat
          const Text(
            'LOMPAT CEPAT KE JADWAL SHOLAT (H-30 DETIK):',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SimButton(label: 'Uji Imsak', onPressed: () => _jumpToPrayer('IMSAK')),
              _SimButton(label: 'Uji Subuh', onPressed: () => _jumpToPrayer('SUBUH')),
              _SimButton(label: 'Uji Syuruq', onPressed: () => _jumpToPrayer('SYURUQ')),
              _SimButton(label: 'Uji Dhuha', onPressed: () => _jumpToPrayer('DHUHA')),
              _SimButton(label: 'Uji Dzuhur', onPressed: () => _jumpToPrayer('DZUHUR')),
              _SimButton(label: 'Uji Ashar', onPressed: () => _jumpToPrayer('ASHAR')),
              _SimButton(label: 'Uji Maghrib', onPressed: () => _jumpToPrayer('MAGHRIB')),
              _SimButton(label: 'Uji Isya', onPressed: () => _jumpToPrayer('ISYA')),
              _SimButton(
                label: 'Uji Sholat Jumat (11:58)',
                onPressed: _jumpToFriday,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Bagian 2: Maju / Mundur Bertahap
          const Text(
            'MAJUKAN / MUNDURKAN WAKTU BERTAHAP:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const SizedBox(
                    width: 70,
                    child: Text(
                      'Menit:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  _SimButton(
                    label: '-10 Menit',
                    onPressed: () => timeService.addOffset(const Duration(minutes: -10)),
                  ),
                  _SimButton(
                    label: '-5 Menit',
                    onPressed: () => timeService.addOffset(const Duration(minutes: -5)),
                  ),
                  _SimButton(
                    label: '-1 Menit',
                    onPressed: () => timeService.addOffset(const Duration(minutes: -1)),
                  ),
                  _SimButton(
                    label: '+1 Menit',
                    onPressed: () => timeService.addOffset(const Duration(minutes: 1)),
                  ),
                  _SimButton(
                    label: '+5 Menit',
                    onPressed: () => timeService.addOffset(const Duration(minutes: 5)),
                  ),
                  _SimButton(
                    label: '+10 Menit',
                    onPressed: () => timeService.addOffset(const Duration(minutes: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const SizedBox(
                    width: 70,
                    child: Text(
                      'Jam:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  _SimButton(
                    label: '-2 Jam',
                    onPressed: () => timeService.addOffset(const Duration(hours: -2)),
                  ),
                  _SimButton(
                    label: '-1 Jam',
                    onPressed: () => timeService.addOffset(const Duration(hours: -1)),
                  ),
                  _SimButton(
                    label: '+1 Jam',
                    onPressed: () => timeService.addOffset(const Duration(hours: 1)),
                  ),
                  _SimButton(
                    label: '+2 Jam',
                    onPressed: () => timeService.addOffset(const Duration(hours: 2)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const SizedBox(
                    width: 70,
                    child: Text(
                      'Hari:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  _SimButton(
                    label: '-7 Hari',
                    onPressed: () => timeService.addOffset(const Duration(days: -7)),
                  ),
                  _SimButton(
                    label: '-1 Hari',
                    onPressed: () => timeService.addOffset(const Duration(days: -1)),
                  ),
                  _SimButton(
                    label: '+1 Hari',
                    onPressed: () => timeService.addOffset(const Duration(days: 1)),
                  ),
                  _SimButton(
                    label: '+7 Hari',
                    onPressed: () => timeService.addOffset(const Duration(days: 7)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Bagian 3: Manual & Reset
          const Text(
            'KONTROL TAMBAHAN & RESET:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _SimButton(
                label: 'Pilih Tanggal & Jam Manual',
                onPressed: _pickDateTime,
              ),
              _SimButton(
                label: 'Reset ke Waktu Asli',
                onPressed: () {
                  timeService.reset();
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SimButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        focusColor: const Color(0xFF0F172A).withValues(alpha: 0.15),
        hoverColor: const Color(0xFF0F172A).withValues(alpha: 0.08),
        onTap: onPressed,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            Scrollable.ensureVisible(
              context,
              alignment: 0.75,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF64748B), width: 1.5),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}
