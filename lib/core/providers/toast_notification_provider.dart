import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../constants/app_colors.dart';

class ToastNotificationState {
  final bool isVisible;
  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;

  const ToastNotificationState({
    this.isVisible = false,
    this.title = '',
    this.message = '',
    this.icon = TablerIcons.refresh,
    this.accentColor = AppColors.bgGreen,
  });

  ToastNotificationState copyWith({
    bool? isVisible,
    String? title,
    String? message,
    IconData? icon,
    Color? accentColor,
  }) {
    return ToastNotificationState(
      isVisible: isVisible ?? this.isVisible,
      title: title ?? this.title,
      message: message ?? this.message,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

final toastNotificationProvider =
    NotifierProvider<ToastNotificationNotifier, ToastNotificationState>(
  ToastNotificationNotifier.new,
);

class ToastNotificationNotifier extends Notifier<ToastNotificationState> {
  Timer? _hideTimer;

  @override
  ToastNotificationState build() {
    ref.onDispose(() {
      _hideTimer?.cancel();
    });
    return const ToastNotificationState();
  }

  void show({
    required String title,
    required String message,
    IconData icon = TablerIcons.refresh,
    Color accentColor = AppColors.bgGreen,
    Duration duration = const Duration(seconds: 4),
  }) {
    _hideTimer?.cancel();
    state = ToastNotificationState(
      isVisible: true,
      title: title,
      message: message,
      icon: icon,
      accentColor: accentColor,
    );

    _hideTimer = Timer(duration, () {
      hide();
    });
  }

  void hide() {
    _hideTimer?.cancel();
    state = state.copyWith(isVisible: false);
  }

  /// Menampilkan notifikasi pembaruan konten masjid dari admin
  void showContentUpdateToast(String? type) {
    final label = _getHumanReadableType(type);
    show(
      title: 'Pembaruan Konten Diterima',
      message: '$label berhasil disinkronkan',
      icon: TablerIcons.cloud_download,
      accentColor: AppColors.bgGreen,
      duration: const Duration(seconds: 4),
    );
  }

  /// Menampilkan notifikasi pembaruan konten global dari admin
  void showGlobalUpdateToast(String? type) {
    final label = _getHumanReadableType(type);
    show(
      title: 'Pembaruan Global Diterima',
      message: '$label berhasil disinkronkan',
      icon: TablerIcons.broadcast,
      accentColor: AppColors.primary,
      duration: const Duration(seconds: 4),
    );
  }

  String _getHumanReadableType(String? type) {
    if (type == null || type.isEmpty) return 'Data Konten Masjid';
    switch (type.toLowerCase()) {
      case 'marquee':
        return 'Teks Berjalan (Marquee)';
      case 'slide':
        return 'Slide Gambar';
      case 'agenda':
        return 'Agenda Kegiatan';
      case 'laporan':
        return 'Laporan Keuangan';
      case 'theme':
        return 'Tema Tampilan';
      case 'profil':
        return 'Profil Masjid';
      case 'jumbotron':
      case 'jumbotron_masjid':
        return 'Jumbotron Masjid';
      case 'jumbotron_pemko':
        return 'Jumbotron Pemko';
      case 'audio-murottal':
      case 'murottal':
        return 'Audio Murottal';
      case 'audio-adzan':
        return 'Audio Adzan';
      case 'adzan':
        return 'Tampilan Adzan';
      case 'petugas':
        return 'Petugas Sholat';
      case 'durasi':
        return 'Pengaturan Durasi';
      default:
        return 'Konten ($type)';
    }
  }
}
