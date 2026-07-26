import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constant.dart';
import '../../../core/providers/selected_profil_provider.dart';

class JumbotronMasjidScreen extends ConsumerWidget {
  const JumbotronMasjidScreen({super.key});

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
    final String logo = _getFullUrl(profil?.logoMasjid);
    final bool hasLogo = logo.isNotEmpty;

    Widget logoWidget;
    final double logoSize = 600.0; // Sangat besar

    if (!hasLogo) {
      logoWidget = Image.asset(
        'assets/logo/logo-masjid-default.png',
        height: logoSize,
        fit: BoxFit.contain,
      );
    } else {
      logoWidget = Image.network(
        logo,
        height: logoSize,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => Icon(
          Icons.mosque,
          size: logoSize,
          color: Colors.white,
        ),
      );
    }

    return TvScaffold(
      backgroundColor: AppColors.bgDark, // Background gelap elegan
      body: Stack(
        children: [
          // Efek glow di belakang logo (opsional)
          Center(
            child: Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
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
                Text(
                  profil?.name.toUpperCase() ?? 'MASJID DEMO KOTA PEKANBARU',
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 16,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  profil?.address ?? 'Jl. Jenderal Sudirman, Pekanbaru',
                  style: const TextStyle(
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
