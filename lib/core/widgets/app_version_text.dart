import 'package:flutter/material.dart';

/// Widget core untuk menampilkan informasi versi aplikasi dari pubspec.yaml.
/// Secara default menampilkan 3 digit versi publik (contoh: v.2.3.0).
class AppVersionText extends StatelessWidget {
  /// Nama aplikasi
  static const String appName = 'JWS Diskominfo';

  /// Versi rilis 3 digit (MAJOR.MINOR.PATCH)
  static const String versionName = '2.3.0';

  /// Nomor build internal (versionCode)
  static const String buildNumber = '9';

  /// Versi lengkap pubspec termasuk build number (2.3.0+9)
  static const String fullVersion = '$versionName+$buildNumber';

  /// Versi default yang ditampilkan ke pengguna (3 digit: 2.3.0)
  static const String version = versionName;

  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final bool showAppName;
  final bool showV;
  final bool withDotAfterV;
  final bool showBuildNumber;
  final bool withParentheses;

  const AppVersionText({
    super.key,
    this.style,
    this.prefix,
    this.suffix,
    this.showAppName = true,
    this.showV = true,
    this.withDotAfterV = true,
    this.showBuildNumber = false,
    this.withParentheses = true,
  });

  /// Helper untuk mendapatkan teks string versi secara langsung
  static String text({
    bool showAppName = true,
    bool showV = true,
    bool withDotAfterV = true,
    bool showBuildNumber = false,
    bool withParentheses = true,
    String? prefix,
    String? suffix,
  }) {
    final vPrefix = showV ? (withDotAfterV ? 'v.' : 'v') : '';
    final verNumber = showBuildNumber ? fullVersion : versionName;
    final vStr = '$vPrefix$verNumber';

    if (prefix != null || suffix != null) {
      return '${prefix ?? ''}$vStr${suffix ?? ''}';
    }
    if (showAppName) {
      return withParentheses ? '($appName $vStr)' : '$appName $vStr';
    }
    return withParentheses ? '($vStr)' : vStr;
  }

  /// Helper untuk membuat TextSpan (misal di dalam Text.rich)
  static TextSpan span({
    TextStyle? style,
    bool showAppName = true,
    bool showV = true,
    bool withDotAfterV = true,
    bool showBuildNumber = false,
    bool withParentheses = true,
    String? prefix,
    String? suffix,
  }) {
    return TextSpan(
      text: text(
        showAppName: showAppName,
        showV: showV,
        withDotAfterV: withDotAfterV,
        showBuildNumber: showBuildNumber,
        withParentheses: withParentheses,
        prefix: prefix,
        suffix: suffix,
      ),
      style: style,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text(
        showAppName: showAppName,
        showV: showV,
        withDotAfterV: withDotAfterV,
        showBuildNumber: showBuildNumber,
        withParentheses: withParentheses,
        prefix: prefix,
        suffix: suffix,
      ),
      style: style ??
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.black54,
          ),
    );
  }
}
