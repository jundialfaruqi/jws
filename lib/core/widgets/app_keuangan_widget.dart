import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:sticky_headers/sticky_headers.dart';
import '../../features/main/models/laporan_keuangan_model.dart';
import '../constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../time/time_sync_service.dart';

class AppKeuanganWidget extends ConsumerStatefulWidget {
  final LaporanKeuanganDataModel? laporanData;
  final int scrollSpeed;
  final EdgeInsetsGeometry? margin;
  final bool showRightBorder;

  const AppKeuanganWidget({
    super.key,
    required this.laporanData,
    this.scrollSpeed = 40,
    this.margin,
    this.showRightBorder = true,
  });

  @override
  ConsumerState<AppKeuanganWidget> createState() => _AppKeuanganWidgetState();
}

class _AppKeuanganWidgetState extends ConsumerState<AppKeuanganWidget>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late Ticker _ticker;
  double _contentHeight = 0.0;
  bool _isHeightCalculated = false;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ticker.start();
    });
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !_scrollController.hasClients) return;

    // Hitung tinggi 1 set konten jika belum
    if (!_isHeightCalculated) {
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent > 0) {
        // Karena kita merender 2 set konten identik (plus header),
        // kita akan menghitung tinggi per set nanti setelah frame dirender penuh.
        // Untuk sekarang, kita asumsikan jika bisa scroll, kita cari tingginya.
      }
    }

    if (_contentHeight == 0.0) return;

    // Logika Sinkronisasi Jam Dunia (Keajaiban Sinkronisasi)
    final int nowMs = ref
        .read(timeSyncServiceProvider)
        .now()
        .millisecondsSinceEpoch;

    // Kecepatan dalam pixel per detik (base speed 30.0 * multiplier)
    final double baseSpeed = 30.0;
    final double multiplier = widget.scrollSpeed > 0
        ? widget.scrollSpeed.toDouble()
        : 1.0;
    final double speed = baseSpeed * multiplier;

    // Jarak absolut yang seharusnya ditempuh berdasarkan waktu
    final double distance = (nowMs / 1000.0) * speed;

    // Hitung sisa jarak agar animasi berulang (looping) secara mulus di dalam 1 set konten
    final double position = distance % _contentHeight;

    // Update posisi scroll secara melompat (jumpTo) dengan pembulatan agar StickyHeader tidak gempa
    _scrollController.jumpTo(position.floorToDouble());
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (widget.laporanData == null || widget.laporanData!.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final data = widget.laporanData!;
    final grandTotals = data.grandTotals;

    List<Widget> scrollItems = [
      _buildGrandTotalSection(grandTotals, currencyFormatter),
      const SizedBox(height: 32),
    ];
    for (var group in data.categories) {
      scrollItems.add(_buildCategorySection(group, currencyFormatter));
    }

    return Container(
      width: 500,
      margin:
          widget.margin ??
          const EdgeInsets.only(top: 0, bottom: 0, left: 0, right: 0),
      decoration: BoxDecoration(
        color: AppColors.bgNavy.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(0),
        border: widget.showRightBorder
            ? Border(
                right: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.0,
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // STICKY HEADER (PERIODE)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgDark.withValues(alpha: 0.8),
            ),
            child: Text(
              "PERIODE ${data.periodeString.toUpperCase()}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // SCROLLING CONTENT
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Ukur tinggi konten segera setelah dirender
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final renderBox =
                      _contentKey.currentContext?.findRenderObject()
                          as RenderBox?;
                  if (renderBox != null &&
                      _contentHeight != renderBox.size.height) {
                    setState(() {
                      _contentHeight = renderBox.size.height;
                      _isHeightCalculated = true;
                    });
                  }
                });

                return SingleChildScrollView(
                  controller: _scrollController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Scroll hanya via Ticker
                  child: Column(
                    children: [
                      // Set Konten Asli (Diukur Tingginya)
                      Container(
                        key: _contentKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: scrollItems,
                        ),
                      ),
                      // Set Konten Bayangan 1 (Untuk Seamless Looping)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: scrollItems,
                      ),
                      // Set Konten Bayangan 2 (Jaga-jaga jika tinggi layar sangat besar)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: scrollItems,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalSection(GrandTotalsModel totals, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: AppColors.bgPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(0),
        // border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TOTAL KESELURUHAN",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            "Total Uang Masuk",
            fmt.format(totals.sumMasuk),
            Colors.greenAccent,
          ),
          _buildSummaryRow(
            "Total Uang Keluar",
            fmt.format(totals.sumKeluar),
            Colors.redAccent,
          ),
          const Divider(color: Colors.white24, height: 24),
          _buildSummaryRow(
            "Total Akhir Saldo",
            fmt.format(totals.ending),
            AppColors.textYellow,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    LaporanKeuanganGroupModel group,
    NumberFormat fmt,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: StickyHeader(
        header: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgBlue,
            borderRadius: BorderRadius.circular(0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            group.categoryName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const SizedBox(height: 16),
            // SUMMARY KATEGORI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(0),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    "Pemasukan",
                    fmt.format(group.sumMasuk),
                    Colors.greenAccent,
                  ),
                  _buildSummaryRow(
                    "Pengeluaran",
                    fmt.format(group.sumKeluar),
                    Colors.redAccent,
                  ),
                  const Divider(color: Colors.white24, height: 16),
                  _buildSummaryRow(
                    "Total",
                    fmt.format(group.ending),
                    Colors.white,
                  ),
                  _buildSummaryRow(
                    "Saldo Sebelumnya",
                    fmt.format(group.saldoSebelumnya),
                    Colors.white,
                  ),
                  const Divider(color: Colors.white24, height: 16),
                  _buildSummaryRow(
                    "Saldo Akhir",
                    fmt.format(group.saldoAkhir),
                    AppColors.textYellow,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 32,
            ), // Jarak lebih luas antara rincian item dengan card summary
            // TRANSAKSI
            ...group.items.map((item) => _buildTransactionItem(item, fmt)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    String amount,
    Color color, {
    bool isBold = false,
  }) {
    final cleanAmount = amount.replaceAll('Rp', '').trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70, // Label lebih pudar
              fontSize: 24, // Sedikit lebih kecil
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "Rp",
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  cleanAmount,
                  style: TextStyle(
                    color: color,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1, // Merapatkan sedikit agar dinamis
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    LaporanKeuanganItemModel item,
    NumberFormat fmt,
  ) {
    final isMasuk = item.jenis.toLowerCase() == 'masuk';

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Jarak antar item diperlebar
      padding: const EdgeInsets.all(
        16,
      ), // Jarak ke dalam (padding) item diperlebar
      decoration: BoxDecoration(
        color: isMasuk
            ? Colors.greenAccent.withValues(alpha: 0.1)
            : Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                color: isMasuk ? Colors.greenAccent : Colors.redAccent,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.uraian,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.tanggal,
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "Rp",
                  style: TextStyle(
                    color: isMasuk
                        ? Colors.greenAccent.withValues(alpha: 0.8)
                        : Colors.redAccent.withValues(alpha: 0.8),
                    fontSize: 20, // Rp lebih kecil
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  fmt.format(item.saldo).replaceAll('Rp', '').trim(),
                  style: TextStyle(
                    color: isMasuk ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
