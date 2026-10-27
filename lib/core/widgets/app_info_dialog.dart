import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/main/models/my_masjid_model.dart';
import '../../features/main/providers/my_masjid_provider.dart';
import '../providers/selected_profil_provider.dart';
import 'app_version_text.dart';
import 'tv/tv_button.dart';

class AppInfoDialog extends ConsumerWidget {
  const AppInfoDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const AppInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProfil = ref.watch(selectedProfilProvider);
    final myMasjidAsync = selectedProfil != null
        ? ref.watch(myMasjidProvider(selectedProfil.id))
        : null;

    final bool isSyncing = myMasjidAsync != null &&
        (myMasjidAsync.isLoading || myMasjidAsync.isRefreshing);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 820,
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Dialog
              Row(
                children: [
                  Image.asset(
                    'assets/logo/diskominfotiksan-logo.png',
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'INFORMASI SINKRONISASI DATA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                'v.${AppVersionText.versionName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedProfil != null
                              ? '${selectedProfil.name}${selectedProfil.address != null && selectedProfil.address!.isNotEmpty ? ' • ${selectedProfil.address}' : ''}'
                              : 'Perangkat Belum Terhubung',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),

              // Konten Status Data
              if (selectedProfil == null)
                _buildUnlinkedState()
              else if (myMasjidAsync == null ||
                  (myMasjidAsync.isLoading && !myMasjidAsync.hasValue))
                _buildLoadingState()
              else if (myMasjidAsync.hasError && !myMasjidAsync.hasValue)
                _buildErrorState(myMasjidAsync.error.toString())
              else
                _buildSyncGrid(myMasjidAsync.value!),

              const SizedBox(height: 12),

              // Catatan Bantuan untuk Admin
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFF3B82F6),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jika data di TV belum sesuai dengan Web Admin, pastikan admin telah klik Simpan di web, lalu tekan tombol "Sinkron Ulang".',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons Row (di dalam flow konten agar tidak pernah memotong isi)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedProfil != null) ...[
                    TvButton(
                      label: isSyncing ? 'Menyinkronkan...' : 'Sinkron Ulang',
                      icon: isSyncing
                          ? Icons.hourglass_top_rounded
                          : Icons.refresh_rounded,
                      variant: TvButtonVariant.ghost,
                      fontSize: 14,
                      onPressed: isSyncing
                          ? () {}
                          : () {
                              ref.invalidate(myMasjidProvider(selectedProfil.id));
                            },
                    ),
                    const SizedBox(width: 14),
                  ],
                  TvButton(
                    label: 'Tutup',
                    autofocus: true,
                    fontSize: 14,
                    variant: TvButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 12),
            Text(
              'Memeriksa ketersediaan data di TV...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gagal memuat data dari server',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  error,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFB91C1C),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlinkedState() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: const [
          Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD97706),
            size: 24,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'TV belum terhubung dengan profil masjid manapun. Hubungkan TV melalui menu pairing terlebih dahulu.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncGrid(MyMasjidModel data) {
    // 1. Jadwal Sholat
    final bool hasJadwal = data.jadwalSholat.isNotEmpty;
    final String jadwalDesc = hasJadwal
        ? 'Tersedia (${data.jadwalSholat.length} jadwal)'
        : 'Belum tersedia';

    // 2. Marquee
    final customMarquees = [
      data.marquee?.marquee1,
      data.marquee?.marquee2,
      data.marquee?.marquee3,
      data.marquee?.marquee4,
      data.marquee?.marquee5,
      data.marquee?.marquee6,
    ].where((m) => m != null && m.trim().isNotEmpty).toList();
    final bool hasMarquee = customMarquees.isNotEmpty;
    final String marqueeDesc = hasMarquee
        ? 'Tersedia (${customMarquees.length} teks kustom)'
        : 'Belum tersedia (pakai default)';

    // 3. Slide Informasi
    final slidesList = data.slides?.validSlides ?? [];
    final bool hasSlides = slidesList.isNotEmpty;
    final String slidesDesc = hasSlides
        ? 'Tersedia (${slidesList.length} slide gambar)'
        : 'Belum tersedia';

    // 4. Jumbotron Layar Penuh
    final bool hasPemko =
        (data.jumbotronPemko?.validSlides.isNotEmpty ?? false) ||
        (data.jumbotronPemko?.isVideo ?? false);
    final bool hasMasjid =
        (data.jumbotronMasjid?.validSlides.isNotEmpty ?? false) ||
        (data.jumbotronMasjid?.isVideo ?? false);
    final bool hasJumbotron = hasPemko || hasMasjid;
    final String jumbotronDesc = hasJumbotron
        ? [if (hasMasjid) 'Masjid', if (hasPemko) 'Pemko'].join(' & ')
        : 'Belum tersedia';

    // 5. Petugas Sholat Jumat
    final bool hasPetugas = data.petugasJumat.isNotEmpty &&
        data.petugasJumat.any(
          (p) => p.khatib.trim().isNotEmpty || p.imam.trim().isNotEmpty,
        );
    final String petugasDesc = hasPetugas
        ? 'Tersedia (${data.petugasJumat.first.tanggalFormat})'
        : 'Belum diisi di web admin';

    // 6. Agenda Kegiatan
    final bool hasAgenda = data.agenda.isNotEmpty;
    final String agendaDesc = hasAgenda
        ? 'Tersedia (${data.agenda.length} agenda)'
        : 'Belum tersedia';

    // 7. Laporan Keuangan
    final bool hasKeuangan = data.laporanKeuangan != null &&
        data.laporanKeuangan!.categories.isNotEmpty;
    final String keuanganDesc = hasKeuangan
        ? 'Tersedia (${data.laporanKeuangan!.categories.length} kategori kas)'
        : 'Belum diisi di web admin';

    // 8. Pengaturan Durasi & Iqomah
    final bool hasDurasi = data.durasi != null;
    final String durasiDesc = hasDurasi ? 'Tersedia' : 'Belum diatur';

    // 9. Audio Adzan & Murotal
    final bool hasAdzan = (data.audioAdzan?.status ?? false) &&
        ((data.audioAdzan?.audioAdzan?.isNotEmpty ?? false) ||
            (data.audioAdzan?.adzanShubuh?.isNotEmpty ?? false));
    final bool hasMurotal = (data.audioMurotal?.status ?? false) &&
        ((data.audioMurotal?.audio1?.isNotEmpty ?? false) ||
            (data.audioMurotal?.audio2?.isNotEmpty ?? false) ||
            (data.audioMurotal?.audio3?.isNotEmpty ?? false));
    final bool hasAudio = hasAdzan || hasMurotal;
    final String audioDesc = hasAudio
        ? [if (hasAdzan) 'Adzan', if (hasMurotal) 'Murotal'].join(' & ')
        : 'Belum diaktifkan';

    // 10. Slide Transisi Sholat
    final bool hasSlideTransisi =
        (data.slideIqomah?.validSlides.isNotEmpty ?? false) ||
        (data.slideFinal?.validSlides.isNotEmpty ?? false);
    final String transisiDesc = hasSlideTransisi
        ? 'Tersedia (Kustom)'
        : 'Tersedia (Bawaan tema)';

    final leftItems = [
      _SyncItemData(
        title: 'Jadwal Sholat',
        detail: jadwalDesc,
        isAvailable: hasJadwal,
      ),
      _SyncItemData(
        title: 'Teks Marquee',
        detail: marqueeDesc,
        isAvailable: hasMarquee,
      ),
      _SyncItemData(
        title: 'Slide Gambar',
        detail: slidesDesc,
        isAvailable: hasSlides,
      ),
      _SyncItemData(
        title: 'Jumbotron Fullscreen',
        detail: jumbotronDesc,
        isAvailable: hasJumbotron,
      ),
      _SyncItemData(
        title: 'Durasi & Iqomah',
        detail: durasiDesc,
        isAvailable: hasDurasi,
      ),
    ];

    final rightItems = [
      _SyncItemData(
        title: 'Petugas Sholat Jumat',
        detail: petugasDesc,
        isAvailable: hasPetugas,
      ),
      _SyncItemData(
        title: 'Agenda Kegiatan',
        detail: agendaDesc,
        isAvailable: hasAgenda,
      ),
      _SyncItemData(
        title: 'Laporan Keuangan',
        detail: keuanganDesc,
        isAvailable: hasKeuangan,
      ),
      _SyncItemData(
        title: 'Audio Adzan & Tarhim',
        detail: audioDesc,
        isAvailable: hasAudio,
      ),
      _SyncItemData(
        title: 'Slide Transisi Sholat',
        detail: transisiDesc,
        isAvailable: true,
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: leftItems.map((item) => _buildItemRow(item)).toList(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: rightItems.map((item) => _buildItemRow(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(_SyncItemData item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.isAvailable
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isAvailable
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFFECACA),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            item.isAvailable
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: item.isAvailable
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: item.isAvailable
                  ? const Color(0xFF14532D)
                  : const Color(0xFF7F1D1D),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            ':',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.detail,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: item.isAvailable
                    ? const Color(0xFF15803D)
                    : const Color(0xFFDC2626),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncItemData {
  final String title;
  final String detail;
  final bool isAvailable;

  const _SyncItemData({
    required this.title,
    required this.detail,
    required this.isAvailable,
  });
}
