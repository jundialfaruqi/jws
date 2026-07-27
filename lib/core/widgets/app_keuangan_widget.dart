import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../features/main/models/laporan_keuangan_model.dart';
import '../constants/app_colors.dart';

class AppKeuanganWidget extends StatefulWidget {
  final LaporanKeuanganDataModel? laporanData;
  final int scrollSpeed;

  const AppKeuanganWidget({
    super.key,
    required this.laporanData,
    this.scrollSpeed = 40,
  });

  @override
  State<AppKeuanganWidget> createState() => _AppKeuanganWidgetState();
}

class _AppKeuanganWidgetState extends State<AppKeuanganWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() async {
    if (!mounted) return;
    _isScrolling = true;
    _scrollLoop();
  }

  void _scrollLoop() async {
    if (!mounted || !_isScrolling || !_scrollController.hasClients) return;
    
    // Hitung durasi berdasarkan kecepatan (pixels per second)
    // Anggap base speed adalah 30.0
    // Jika API mengirim scrollSpeed = 3, maka speed = 90.0 (makin cepat)
    final double baseSpeed = 30.0;
    final double multiplier =
        (widget.scrollSpeed > 0) ? widget.scrollSpeed.toDouble() : 1.0;
    final double speed = baseSpeed * multiplier;
    
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.laporanData == null || widget.laporanData!.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFormatter =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    final data = widget.laporanData!;
    final grandTotals = data.grandTotals;

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
          // STICKY HEADER (PERIODE)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgDark.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              "PERIODE ${data.periodeString.toUpperCase()}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // SCROLLING CONTENT
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // GRAND TOTALS
                  _buildGrandTotalSection(grandTotals, currencyFormatter),
                  const SizedBox(height: 32),
                  
                  // CATEGORIES & TRANSACTIONS
                  ...data.categories.map((group) {
                     return _buildCategorySection(group, currencyFormatter);
                  }),
                ],
              ),
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
        color: AppColors.bgPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TOTAL KESELURUHAN",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow("Total Uang Masuk", fmt.format(totals.sumMasuk), Colors.greenAccent),
          _buildSummaryRow("Total Uang Keluar", fmt.format(totals.sumKeluar), Colors.redAccent),
          const Divider(color: Colors.white24, height: 24),
          _buildSummaryRow("Total Akhir Saldo", fmt.format(totals.ending), AppColors.textYellow, isBold: true),
        ],
      ),
    );
  }

  Widget _buildCategorySection(LaporanKeuanganGroupModel group, NumberFormat fmt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NAMA KATEGORI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              group.categoryName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // SUMMARY KATEGORI
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                _buildSummaryRow("Pemasukan", fmt.format(group.sumMasuk), Colors.greenAccent),
                _buildSummaryRow("Pengeluaran", fmt.format(group.sumKeluar), Colors.redAccent),
                const Divider(color: Colors.white24, height: 16),
                _buildSummaryRow("Total", fmt.format(group.ending), Colors.white),
                _buildSummaryRow("Saldo Sebelumnya", fmt.format(group.saldoSebelumnya), Colors.white54),
                const Divider(color: Colors.white24, height: 16),
                _buildSummaryRow("Saldo Akhir", fmt.format(group.saldoAkhir), AppColors.textYellow, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // TRANSAKSI
          ...group.items.map((item) => _buildTransactionItem(item, fmt)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String amount, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(LaporanKeuanganItemModel item, NumberFormat fmt) {
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
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.tanggal,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(item.saldo),
                style: TextStyle(
                  color: isMasuk ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isMasuk ? "Masuk" : "Keluar",
                style: TextStyle(
                  color: isMasuk ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
