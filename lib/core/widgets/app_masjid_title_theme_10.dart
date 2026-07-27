import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/api_constant.dart';

class AppMasjidTitleTheme10 extends StatelessWidget {
  final String title;
  final String? address;
  final Color backgroundColor;
  final Color textColor;
  final Color? addressColor;
  final String? logoMasjid;
  final String? logoPemerintah;
  final bool isRightAligned;
  final bool isLeftAligned;
  final bool showText;

  const AppMasjidTitleTheme10({
    super.key,
    required this.title,
    this.address,
    this.backgroundColor = Colors.transparent,
    this.textColor = Colors.white,
    this.addressColor,
    this.logoMasjid,
    this.logoPemerintah,
    this.isRightAligned = false,
    this.isLeftAligned = false,
    this.showText = true,
  });

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
  Widget build(BuildContext context) {
    final String logo1 = _getFullUrl(logoMasjid);
    final String logo2 = _getFullUrl(logoPemerintah);
    final bool hasLogo1 = logo1.isNotEmpty;
    final bool hasLogo2 = logo2.isNotEmpty;

    List<Widget> logoWidgets = [];

    final double logoSize = 100.0;

    if (!hasLogo1 && !hasLogo2) {
      logoWidgets.add(
        Image.asset(
          'assets/logo/logo-masjid-default.png',
          height: logoSize,
          fit: BoxFit.contain,
        ),
      );
      logoWidgets.add(const SizedBox(width: 4));
      logoWidgets.add(
        Image.asset(
          'assets/logo/logo-pemko-default.png',
          height: logoSize,
          fit: BoxFit.contain,
        ),
      );
    } else {
      if (hasLogo1) {
        logoWidgets.add(
          CachedNetworkImage(
            imageUrl: logo1,
            height: logoSize,
            fit: BoxFit.contain,
            errorWidget: (context, url, error) =>
                Icon(Icons.mosque, size: logoSize, color: Colors.white),
          ),
        );
      }
      if (hasLogo2) {
        if (hasLogo1) logoWidgets.add(const SizedBox(width: 4));
        logoWidgets.add(
          CachedNetworkImage(
            imageUrl: logo2,
            height: logoSize,
            fit: BoxFit.contain,
            errorWidget: (context, url, error) => Icon(
              Icons.account_balance,
              size: logoSize,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    if (!showText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: logoWidgets,
      );
    }

    // Teks widget builder agar tidak berulang
    Widget buildTextColumn(CrossAxisAlignment alignment, TextAlign textAlign) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Poppins',
              letterSpacing: 1.5,
              height: 1.0,
            ),
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (address != null && address!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              address!,
              style: TextStyle(
                fontSize: 28,
                color: addressColor ?? textColor.withValues(alpha: 0.8),
                fontFamily: 'Poppins',
              ),
              textAlign: textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );
    }

    List<Widget> rowChildren = [];

    if (isLeftAligned) {
      // LOGO -> TEKS (KIRI)
      rowChildren = [
        ...logoWidgets,
        const SizedBox(width: 24),
        buildTextColumn(CrossAxisAlignment.start, TextAlign.left),
      ];
    } else if (isRightAligned) {
      // TEKS -> LOGO (KANAN)
      rowChildren = [
        buildTextColumn(CrossAxisAlignment.end, TextAlign.right),
        const SizedBox(width: 24),
        ...logoWidgets,
      ];
    } else {
      // DEFAULT / CENTER (TEKS DI TENGAH, LOGO DI KANAN)
      rowChildren = [
        const Expanded(child: SizedBox()),
        buildTextColumn(CrossAxisAlignment.center, TextAlign.center),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: logoWidgets,
          ),
        ),
      ];
    }

    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 24, left: 48, right: 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            backgroundColor.withValues(alpha: 1.0), // Kiri solid penuh
            backgroundColor.withValues(
              alpha: 1.0,
            ), // Tetap solid sampai menjelang kanan
            backgroundColor.withValues(
              alpha: 0.1,
            ), // Memudar cepat di ujung kanan
          ],
          stops: const [
            0.0,
            0.50,
            1.0,
          ], // Transparan baru mulai di 85% lebar kotak
        ),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(130),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: rowChildren,
      ),
    );
  }
}
