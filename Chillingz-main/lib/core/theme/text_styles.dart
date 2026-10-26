import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const String fontFamily = 'Inter';
  static const double normalLetterSpacing = -0.56;

  static TextStyle heading1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 22 / 18,
    letterSpacing: 0,
  );

  static TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 18 / 14,
    letterSpacing: normalLetterSpacing,
  );

  static TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle button = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
    height: 1.1,
    letterSpacing: normalLetterSpacing,
  );

  static TextStyle link = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    letterSpacing: -0.52,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primary,
  );
}
