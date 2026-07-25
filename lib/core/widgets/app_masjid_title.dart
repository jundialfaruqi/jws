import 'package:flutter/material.dart';
import '../constants/api_constant.dart';

class AppMasjidTitle extends StatelessWidget {
  final String title;
  final String? address;
  final Color backgroundColor;
  final Color textColor;
  final Color? addressColor;
  final String? logoMasjid;
  final String? logoPemerintah;
  final bool isRightAligned;

  const AppMasjidTitle({
    super.key,
    required this.title,
    this.address,
    this.backgroundColor = Colors.transparent,
    this.textColor = Colors.white,
    this.addressColor,
    this.logoMasjid,
    this.logoPemerintah,
    this.isRightAligned = false,
  });

  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    
    final baseUrl = ApiConstant.baseUrl;
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
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
    
    final double logoSize = 160.0; // Ukuran global untuk logo
    
    if (!hasLogo1 && !hasLogo2) {
      logoWidgets.add(
        Image.asset('assets/logo/logo-masjid-default.png', height: logoSize, fit: BoxFit.contain),
      );
    } else {
      if (hasLogo1) {
        logoWidgets.add(
          Image.network(logo1, height: logoSize, fit: BoxFit.contain, 
            errorBuilder: (context, error, stackTrace) => Icon(Icons.mosque, size: logoSize, color: Colors.white),
          ),
        );
      }
      if (hasLogo2) {
        if (hasLogo1) logoWidgets.add(const SizedBox(width: 32));
        logoWidgets.add(
          Image.network(logo2, height: logoSize, fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.account_balance, size: logoSize, color: Colors.white),
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
      color: backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: isRightAligned ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isRightAligned)
            const Expanded(child: SizedBox()),
            
          if (isRightAligned)
            const Expanded(child: SizedBox()), // Dorong dari kiri ke kanan
          
          // Bagian Teks
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: 'Poppins',
                  letterSpacing: 1.5,
                ),
                textAlign: isRightAligned ? TextAlign.right : TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (address != null && address!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  address!,
                  style: TextStyle(
                    fontSize: 28,
                    color: addressColor ?? textColor.withValues(alpha: 0.8),
                    fontFamily: 'Poppins',
                  ),
                  textAlign: isRightAligned ? TextAlign.right : TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          
          if (!isRightAligned)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: logoWidgets,
              ),
            )
          else ...[
            const SizedBox(width: 32),
            ...logoWidgets,
          ],
        ],
      ),
    );
  }
}
