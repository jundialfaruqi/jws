import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import '../../features/main/models/laporan_keuangan_model.dart';
import '../constants/app_colors.dart';

class AppKeuanganWidget extends StatefulWidget {
  final LaporanKeuanganDataModel? laporanData;
  final int scrollSpeed;
  final EdgeInsetsGeometry? margin;

  const AppKeuanganWidget({
    super.key,
    required this.laporanData,
    this.scrollSpeed = 40,
    this.margin,
  });

  @override
  State<AppKeuanganWidget> createState() => _AppKeuanganWidgetState();
}

class _AppKeuanganWidgetState extends State<AppKeuanganWidget>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _currentSpeed = 30.0;
  double _targetSpeed = 30.0;

  @override
  void initState() {
    super.initState();
    _targetSpeed = _calculateSpeed(widget.scrollSpeed);
    _currentSpeed = _targetSpeed;

    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ticker.start();
    });
  }

  double _calculateSpeed(int speedValue) {
    final double baseSpeed = 30.0;
    final double multiplier = (speedValue > 0) ? speedValue.toDouble() : 1.0;
    return baseSpeed * multiplier;
  }

  @override
  void didUpdateWidget(AppKeuanganWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollSpeed != widget.scrollSpeed) {
      _targetSpeed = _calculateSpeed(widget.scrollSpeed);
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !_scrollController.hasClients) return;

    final delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    final dt = delta.inMilliseconds / 1000.0; // waktu dalam detik
    if (dt <= 0) return;

    // Transisi kecepatan secara bertahap (Ramp up / Ramp down)
    if ((_targetSpeed - _currentSpeed).abs() > 0.1) {
      // Menyesuaikan kecepatan sedikit demi sedikit setiap frame
      _currentSpeed += (_targetSpeed - _currentSpeed) * 2.0 * dt;
    } else {
      _currentSpeed = _targetSpeed;
    }

    final double dx = _currentSpeed * dt;
    _scrollController.jumpTo(_scrollController.offset + dx);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
              ),
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

          // SCROLLING CONTENT INFINITE
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final itemIndex = index % scrollItems.length;
                return scrollItems[itemIndex];
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
                fontSize: 32,
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
          const SizedBox(height: 16),

          // TRANSAKSI
          ...group.items.map((item) => _buildTransactionItem(item, fmt)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    String amount,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.bold,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(item.saldo),
                style: TextStyle(
                  color: isMasuk ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isMasuk ? "Masuk" : "Keluar",
                style: TextStyle(
                  color: isMasuk ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 24,
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
