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

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  String? _pairingCode;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPairing();
  }

  Future<void> _initPairing() async {
    final deviceService = ref.read(deviceServiceProvider);
    final response = await deviceService.requestPairingCode();

    if (response['status'] == 'linked') {
      // Jika sudah tertaut sebelumnya, langsung muat profil masjid
      await _loadAndSaveProfil(response['masjid_id']);
    } else if (response['status'] == 'pending') {
      // Jika masih pending, tampilkan kode dan tunggu websocket
      setState(() {
        _pairingCode = response['pairing_code'];
        _isLoading = false;
      });
      _listenToWebSocket(await deviceService.getDeviceId());
    } else {
      setState(() {
        _error = response['message'] ?? 'Gagal mengambil kode pairing.';
        _isLoading = false;
      });
    }
  }

  void _listenToWebSocket(String deviceId) {
    final wsService = ref.read(deviceWebSocketServiceProvider);
    // Reconnect (putus koneksi lama jika ada, lalu connect ulang dengan callback baru)
    wsService.reconnect(
      deviceId: deviceId,
      onPairingReceived: (masjidId) {
        _loadAndSaveProfil(masjidId);
      },
    );
  }

  Future<void> _loadAndSaveProfil(int masjidId) async {
    try {
      final dio = Dio();
      // Fetch profil using API (this might need adjusting if your API expects slug instead of id, but assuming we can get profil by ID or just use my-masjid endpoint)
      final res = await dio.get(
        '${ApiConstant.baseUrl}api/v2/my-masjid?id=$masjidId',
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'TAUTKAN TV MASJID',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Buka aplikasi Web Admin Masjid, lalu masukkan kode berikut:',
                style: TextStyle(color: Colors.white70, fontSize: 24),
              ),
              const SizedBox(height: 48),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 24),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.blueAccent, width: 2),
                ),
                child: Text(
                  _isLoading ? '...' : (_pairingCode ?? '...'),
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 16,
                  ),
                ),
              ),
              const SizedBox(height: 64),
              const CircularProgressIndicator(color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                _isLoading ? 'Memuat kode aktivasi...' : 'Menunggu aktivasi...',
                style: const TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
