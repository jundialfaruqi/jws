import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constant.dart';
import '../../../core/providers/selected_profil_provider.dart';

class JumbotronPemkoScreen extends ConsumerWidget {
  const JumbotronPemkoScreen({super.key});

  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    final baseUrl = ApiConstant.baseUrl;
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBase$cleanPath';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(selectedProfilProvider);
    final String logo = _getFullUrl(profil?.logoPemerintah);
    final bool hasLogo = logo.isNotEmpty;

    Widget logoWidget;
    final double logoSize = 600.0;

    if (!hasLogo) {
      logoWidget = Image.asset(
        'assets/logo/logo-pemko-default.png',
        height: logoSize,
        fit: BoxFit.contain,
      );
    } else {
      logoWidget = Image.network(
        logo,
        height: logoSize,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => Icon(
          Icons.account_balance,
          size: logoSize,
          color: Colors.white,
        ),
      );
    }

    return TvScaffold(
      backgroundColor: AppColors.bgDark, 
      body: Stack(
        children: [
          // Efek glow
          Center(
            child: Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                logoWidget,
                const SizedBox(height: 64),
                const Text(
                  'PEMERINTAH KOTA PEKANBARU',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 16,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'DINAS KOMUNIKASI, INFORMATIKA, STATISTIK DAN PERSANDIAN',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    letterSpacing: 4,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
