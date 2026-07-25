import 'package:flutter/material.dart';

class AppMasjidTitle extends StatelessWidget {
  final String title;
  final String? address;
  final Color backgroundColor;
  final Color textColor;
  final Color? addressColor;

  const AppMasjidTitle({
    super.key,
    required this.title,
    this.address,
    this.backgroundColor = Colors.transparent,
    this.textColor = Colors.white,
    this.addressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
      color: backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
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
            textAlign: TextAlign.center,
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
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
