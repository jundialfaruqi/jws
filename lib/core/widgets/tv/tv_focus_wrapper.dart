import 'package:flutter/material.dart';

class TvFocusWrapper extends StatefulWidget {
  final Widget Function(BuildContext context, bool isFocused) builder;
  final VoidCallback? onTap;
  final bool autofocus;
  final BorderRadius? borderRadius;

  const TvFocusWrapper({
    super.key,
    required this.builder,
    this.onTap,
    this.autofocus = false,
    this.borderRadius,
  });

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      onTap: widget.onTap,
      borderRadius: widget.borderRadius,
      // Menghilangkan efek bawaan agar desain fokus bisa dikendalikan sepenuhnya oleh builder
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      child: widget.builder(context, _isFocused),
    );
  }
}
