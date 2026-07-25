import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import '../constants/app_colors.dart';

class AppMarquee extends StatelessWidget {
  final String text;
  final double height;
  final Color backgroundColor;
  final TextStyle textStyle;
  final double velocity;
  final double blankSpace;

  const AppMarquee({
    super.key,
    required this.text,
    this.height = 90.0,
    this.backgroundColor = AppColors.bgDark,
    this.textStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 48,
      color: AppColors.textYellow,
    ),
    this.velocity = 50.0,
    this.blankSpace = 400.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: backgroundColor,
      child: Marquee(
        text: text,
        style: textStyle,
        scrollAxis: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.center,
        blankSpace: blankSpace,
        velocity: velocity,
        pauseAfterRound: const Duration(seconds: 1),
        startPadding: 10.0,
        accelerationDuration: const Duration(seconds: 1),
        accelerationCurve: Curves.linear,
        decelerationDuration: const Duration(milliseconds: 500),
        decelerationCurve: Curves.easeOut,
      ),
    );
  }
}
