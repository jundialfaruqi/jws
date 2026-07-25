import 'package:flutter/material.dart';

class TvFocusWrapper extends StatefulWidget {
  final Widget Function(BuildContext context, bool isFocused) builder;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final BorderRadius? borderRadius;
  final FocusNode? focusNode;

  const TvFocusWrapper({
    super.key,
    required this.builder,
    this.onTap,
    this.onFocusChange,
    this.autofocus = false,
    this.borderRadius,
    this.focusNode,
  });

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
        if (widget.onFocusChange != null) {
          widget.onFocusChange!(hasFocus);
        }
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
