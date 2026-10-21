import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/api_constant.dart';
import '../constants/app_colors.dart';
import 'app_sync_marquee_text.dart';

class AppMasjidTitle extends StatelessWidget {
  final String title;
  final String? address;
  final Color backgroundColor;
  final Color textColor;
  final Color? addressColor;
  final List<Shadow>? shadows;
  final String? logoMasjid;
  final String? logoPemerintah;
  final bool isRightAligned;
  final bool isLeftAligned;
  final bool showText;
  final double? customLogoSize;
  final double titleFontSize;
  final double addressFontSize;
  final double? leftMargin;
  final bool enableMarquee;
  final bool autoShrink;
  final int maxCharThreshold;
  final double? fixedHeight;

  const AppMasjidTitle({
    super.key,
    required this.title,
    this.address,
    this.backgroundColor = Colors.transparent,
    this.textColor = AppColors.textYellow,
    this.addressColor,
    this.shadows = const [
      Shadow(
        offset: Offset(2.0, 2.0),
        blurRadius: 4.0,
        color: Color(0x80000000),
      ),
    ],
    this.logoMasjid,
    this.logoPemerintah,
    this.isRightAligned = false,
    this.isLeftAligned = false,
    this.showText = true,
    this.customLogoSize,
    this.titleFontSize = 64.0,
    this.addressFontSize = 28.0,
    this.leftMargin,
    this.enableMarquee = true,
    this.autoShrink = false,
    this.maxCharThreshold = 28,
    this.fixedHeight,
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

    final double logoSize = customLogoSize ?? 100.0;

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
            memCacheHeight: (logoSize * 2).toInt(),
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
            memCacheHeight: (logoSize * 2).toInt(),
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

    // Perhitungan autoShrink untuk judul masjid jika melebihi batas karakter
    double effectiveTitleFontSize = titleFontSize;
    if (autoShrink && title.length > maxCharThreshold) {
      effectiveTitleFontSize =
          (titleFontSize * (maxCharThreshold / title.length)).clamp(
            24.0,
            titleFontSize,
          );
    }

    // Teks widget builder agar tidak berulang
    Widget buildTextColumn(CrossAxisAlignment alignment, TextAlign textAlign) {
      final textAlignment = isRightAligned
          ? Alignment.centerRight
          : (isLeftAligned ? Alignment.centerLeft : Alignment.center);

      Widget titleWidget;
      if (!enableMarquee) {
        titleWidget = SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: textAlignment,
            child: Text(
              title,
              textAlign: textAlign,
              maxLines: 1,
              style: TextStyle(
                fontSize: effectiveTitleFontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'Poppins',
                letterSpacing: 1.5,
                height: 1.0,
                shadows: shadows,
              ),
            ),
          ),
        );
      } else {
        titleWidget = AppSyncMarqueeText(
          text: title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: 'Poppins',
            letterSpacing: 1.5,
            height: 1.0,
            shadows: shadows,
          ),
          textAlign: textAlign,
          velocity: 60.0,
          blankSpace: 80.0,
        );
      }

      Widget? addressWidget;
      if (address != null && address!.isNotEmpty) {
        if (!enableMarquee) {
          addressWidget = SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: textAlignment,
              child: Text(
                address!,
                textAlign: textAlign,
                maxLines: 1,
                style: TextStyle(
                  fontSize: addressFontSize,
                  color: addressColor ?? textColor.withValues(alpha: 0.8),
                  fontFamily: 'Poppins',
                  height: 1.1,
                ),
              ),
            ),
          );
        } else {
          addressWidget = AppSyncMarqueeText(
            text: address!,
            style: TextStyle(
              fontSize: addressFontSize,
              color: addressColor ?? textColor.withValues(alpha: 0.8),
              fontFamily: 'Poppins',
            ),
            textAlign: textAlign,
            velocity: 50.0,
            blankSpace: 60.0,
          );
        }
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          titleWidget,
          if (addressWidget != null) ...[
            const SizedBox(height: 2),
            addressWidget,
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
        Expanded(
          child: buildTextColumn(CrossAxisAlignment.start, TextAlign.left),
        ),
      ];
    } else if (isRightAligned) {
      // TEKS -> LOGO (KANAN)
      rowChildren = [
        Expanded(
          child: buildTextColumn(CrossAxisAlignment.end, TextAlign.right),
        ),
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
      width: double.infinity,
      height: fixedHeight,
      padding: EdgeInsets.only(
        top: 24,
        bottom: 24,
        left: leftMargin ?? 48,
        right: 24,
      ),
      color: backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: rowChildren,
      ),
    );
  }
}
