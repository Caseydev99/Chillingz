import 'package:flutter/material.dart';

extension Builddd on BuildContext {
  Size get size => MediaQuery.sizeOf(this);

  double get screenHeight => size.height;

  double get screenWidth => size.width;

  double get scaleFactor => (screenWidth / 390).clamp(0.92, 1.18).toDouble();

  bool get isSmallPhone => screenWidth < 360;

  bool get isTablet => screenWidth >= 600;

  double wp(double percentage) => screenWidth * (percentage / 100);

  double hp(double percentage) => screenHeight * (percentage / 100);

  double rs(
    num value, {
    double? min,
    double? max,
  }) {
    final scaled = value.toDouble() * scaleFactor;
    return scaled.clamp(min ?? scaled, max ?? scaled).toDouble();
  }
}

extension SpaceExtension on num {
  SizedBox get hSpace => SizedBox(width: toDouble());

  SizedBox get vSpace => SizedBox(height: toDouble());
}
