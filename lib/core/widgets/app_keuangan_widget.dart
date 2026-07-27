import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../features/main/models/laporan_keuangan_model.dart';
import '../constants/app_colors.dart';

class AppKeuanganWidget extends StatefulWidget {
  final List<LaporanKeuanganGroupModel> laporanKeuangan;
  final int scrollSpeed;

  const AppKeuanganWidget({
    super.key,
    required this.laporanKeuangan,
    this.scrollSpeed = 40,
  });

  @override
  State<AppKeuanganWidget> createState() => _AppKeuanganWidgetState();
}

class _AppKeuanganWidgetState extends State<AppKeuanganWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;
  int _currentGroupIndex = 0;
  Timer? _groupTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
      _startGroupTimer();
    });
  }

  @override
  void didUpdateWidget(AppKeuanganWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika data baru masuk dan lebih dari 1, serta timer belum jalan
    if (widget.laporanKeuangan.length > 1 &&
        oldWidget.laporanKeuangan.length <= 1) {
      _startGroupTimer();
    } else if (widget.laporanKeuangan.length <= 1) {
      _groupTimer?.cancel();
    }
  }

  void _startGroupTimer() {
    _groupTimer?.cancel();
    if (widget.laporanKeuangan.length > 1) {
      _groupTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        if (mounted) {
          setState(() {
            _currentGroupIndex =
                (_currentGroupIndex + 1) % widget.laporanKeuangan.length;
          });
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0); // Kembali ke atas saat grup berganti
          }
        }
      });
    }
  }

  void _startScrolling() async {
    if (!mounted) return;
    _isScrolling = true;
    _scrollLoop();
  }

  void _scrollLoop() async {
    if (!mounted || !_isScrolling || !_scrollController.hasClients) return;
    
    // Hitung durasi berdasarkan kecepatan (pixels per second)
    final double speed =
        (widget.scrollSpeed > 0) ? widget.scrollSpeed.toDouble() : 40.0;
    
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;

    // Jika seluruh konten muat di layar (tidak perlu scroll)
    if (maxScroll <= 0) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && _isScrolling) _scrollLoop();
      return;
    }

    // Jika sudah mencapai dasar scroll
    if (currentScroll >= maxScroll) {
      await Future.delayed(const Duration(seconds: 3)); // Istirahat di bawah
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0); // Langsung lompat ke atas
      }
      if (mounted && _isScrolling) _scrollLoop();
      return;
    }

    // Target scroll adalah maxScrollExtent (sampai mentok ke bawah)
    final double remainingDistance = maxScroll - currentScroll;
    // Hitung waktu yang dibutuhkan secara proporsional sesuai jarak tersisa
    final int durationMs = ((remainingDistance / speed) * 1000).round();

    try {
      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.linear,
      );
    } catch (_) {}

    // Setelah animasi selesai (sampai ke dasar), panggil loop lagi
    if (mounted && _isScrolling) {
      _scrollLoop();
    }
  }

  @override
  void dispose() {
    _isScrolling = false;
    _groupTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.laporanKeuangan.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_currentGroupIndex >= widget.laporanKeuangan.length) {
      _currentGroupIndex = 0; // Fallback jika jumlah berkurang
    }
    
    final group = widget.laporanKeuangan[_currentGroupIndex];
    if (group.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFormatter =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      width: 500,
      margin: const EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 12),
      decoration: BoxDecoration(
        color: AppColors.bgNavy.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER (Tetap / Tidak di-scroll)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgDark.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      group.groupCategoryName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24, // Diperbesar dari 20
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.bgBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Saldo: ${currencyFormatter.format(group.totalSaldoAll)}",
                        style: const TextStyle(
                          color: AppColors.textYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 18, // Diperbesar dari 14
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryBox(
                      title: "Masuk Bulan Ini",
                      amount: currencyFormatter.format(group.sumMasukMonth),
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryBox(
                      title: "Keluar Bulan Ini",
                      amount: currencyFormatter.format(group.sumKeluarMonth),
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // DAFTAR TRANSAKSI (Otomatis Scroll)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: group.items.length,
              itemBuilder: (context, index) {
                final item = group.items[index];
                final isMasuk = item.jenis.toLowerCase() == 'masuk';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMasuk
                          ? Colors.greenAccent.withValues(alpha: 0.3)
                          : Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isMasuk ? Colors.greenAccent : Colors.redAccent,
                        size: 24,
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
                                fontSize: 20, // Diperbesar dari 16
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.tanggal,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 16, // Diperbesar dari 12
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormatter.format(item.saldo),
                            style: TextStyle(
                              color: isMasuk
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 20, // Diperbesar dari 16
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isMasuk ? "Masuk" : "Keluar",
                            style: TextStyle(
                              color: isMasuk
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontSize: 16, // Diperbesar dari 12
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
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

  Widget _buildSummaryBox({
    required String title,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18, // Diperbesar dari 14
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 32, // Diperbesar dari 24
            ),
          ),
        ],
      ),
    );
  }
}
