import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/websocket_service.dart';
import '../models/profil_masjid_model.dart';
// import '../../main/providers/my_masjid_provider.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constant.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/widgets/app_confirm_exit.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  String? _pairingCode;
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initPairing();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPairing() async {
    final deviceService = ref.read(deviceServiceProvider);
    final response = await deviceService.requestPairingCode();

    if (response['status'] == 'linked') {
      // Jika sudah tertaut sebelumnya, langsung muat profil masjid
      await _loadAndSaveProfil(response['masjid_id']);
    } else if (response['status'] == 'pending') {
      // Jika masih pending, tampilkan kode dan tunggu websocket + polling fallback
      setState(() {
        _pairingCode = response['pairing_code'];
        _isLoading = false;
      });
      _startPollingCheck();
      _listenToWebSocket(await deviceService.getDeviceId());
    } else {
      setState(() {
        _error = response['message'] ?? 'Gagal mengambil kode pairing.';
        _isLoading = false;
      });
    }
  }

  void _startPollingCheck() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) return;
      final wsService = ref.read(deviceWebSocketServiceProvider);
      // Jika websocket aktif terhubung, serahkan penerimaan event ke websocket
      // agar tidak membanjiri endpoint request-code
      if (wsService.isConnected) return;

      final deviceService = ref.read(deviceServiceProvider);
      final response = await deviceService.requestPairingCode();
      if (response['status'] == 'linked' && response['masjid_id'] != null) {
        timer.cancel();
        await _loadAndSaveProfil(response['masjid_id']);
      }
    });
  }

  void _listenToWebSocket(String deviceId) {
    final wsService = ref.read(deviceWebSocketServiceProvider);
    // Reconnect (putus koneksi lama jika ada, lalu connect ulang dengan callback baru)
    wsService.reconnect(
      deviceId: deviceId,
      onPairingReceived: (masjidId) {
        _pollingTimer?.cancel();
        _loadAndSaveProfil(masjidId);
      },
    );
  }

  Future<void> _loadAndSaveProfil(dynamic masjidId) async {
    _pollingTimer?.cancel();
    try {
      final dio = Dio();
      final id = int.tryParse(masjidId.toString()) ?? masjidId;
      final res = await dio.get(
        '${ApiConstant.baseUrl}api/v2/my-masjid?id=$id',
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final profilModel = ProfilMasjidModel.fromJson(
          res.data['data']['profil']['data'],
        );

        // Simpan ke selected profil
        ref.read(selectedProfilProvider.notifier).setProfil(profilModel);

        // Simpan ke local storage
        const storage = FlutterSecureStorage();
        await storage.write(
          key: 'selected_profil',
          value: jsonEncode(profilModel.toJson()),
        );

        if (mounted) {
          context.go('/main');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat profil masjid.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppConfirmExit(
      child: TvScaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'TAUTKAN TV MASJID',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Scan QR Code dengan HP Anda atau masukkan kode 6 digit di Web Admin:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 42),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_pairingCode != null)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.15),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data:
                            '${ApiConstant.baseUrl}tv-pairing?code=$_pairingCode',
                        version: QrVersions.auto,
                        size: 440.0,
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  if (_pairingCode != null) const SizedBox(width: 64),
                  Container(
                    height: 488,
                    padding: const EdgeInsets.symmetric(horizontal: 64),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: const Color(0xFFFFD54F),
                        width: 4.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFFD54F,
                          ).withValues(alpha: 0.18),
                          blurRadius: 36,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'KODE PAIRING',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 8,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 20),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _isLoading ? '...' : (_pairingCode ?? '...'),
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 160,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 20,
                              fontFamily: 'JetBrainsMono',
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Masukkan kode ini pada Web Admin',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 4.0,
                      color: Color(0xFFFFD54F),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    _isLoading
                        ? 'Memuat kode aktivasi...'
                        : 'Menunggu aktivasi dari Web Admin...',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
