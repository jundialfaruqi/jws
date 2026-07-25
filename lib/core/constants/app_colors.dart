import 'package:flutter/material.dart';

class AppColors {
  // Mencegah class ini di-instantiate
  AppColors._();

  // ====================
  // Brand Colors
  // ====================
  static const Color primary = Color(0xFF2196F3); // Biru Material Utama
  static const Color primaryDark = Color(0xFF1565C0); // Biru Tua (Hover/Focus)
  static const Color secondary = Color(0xFF90CAF9); // Biru Lembut (Light)
  static const Color secondaryDark = Color(0xFF42A5F5); // Biru Sedang
  static const Color ghost = Color(0xFFE3F2FD); // Biru sangat pucat (Background tipis)

  // ====================
  // Background Colors
  // ====================
  static const Color bgPrimary = Colors.white; // Putih bersih
  static const Color bgSecondary = Color(0xFFF5F5F5); // Putih agak abu-abu
  static const Color bgDark = Color(0xFF041426); // Hitam kebiruan sangat gelap
  static const Color bgBlue = Color(0xFF1E5E9E); // Biru sedang
  static const Color bgNavy = Color(0xFF003366); // Biru dongker gelap
  static const Color bgRed = Color(0xFFE23030); // Merah (bisa untuk peringatan)
  static const Color bgGreen = Color(0xFF10B27D); // Hijau (bisa untuk sukses)

  // ====================
  // Text Colors
  // ====================
  static const Color textPrimary = Color(0xFF212121); // Hitam tajam untuk teks utama
  static const Color textSecondary = Color(0xFF757575); // Abu-abu untuk sub-teks
  static const Color textHint = Color(0xFF9E9E9E); // Abu-abu terang untuk placeholder
  static const Color textInverse = Colors.white; // Putih untuk teks di atas warna gelap
  static const Color textYellow = Color(0xFFFFEB3A); // Kuning terang untuk sorotan (highlight)

  // ====================
  // Status & Alert Colors
  // ====================
  static const Color alert = Color(0xFFD32F2F); // Merah tegas (Error/Danger)
  static const Color alertDark = Color(0xFFB71C1C); // Merah tua (Focus/Hover alert)
  static const Color success = Color(0xFF388E3C); // Hijau (Sukses)
  static const Color warning = Color(0xFFF57C00); // Oranye (Peringatan)
  static const Color info = Color(0xFF0288D1); // Biru (Informasi)

  // ====================
  // Border & Divider
  // ====================
  static const Color border = Color(0xFFE0E0E0); // Abu-abu untuk garis tepi standar
  static const Color borderDark = Color(0xFFBDBDBD); // Abu-abu tua untuk garis tepi yang difokus
  static const Color divider = Color(0xFFEEEEEE); // Abu-abu sangat tipis untuk pemisah antar item
}
