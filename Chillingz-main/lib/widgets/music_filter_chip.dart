import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';

class MusicFilterChip extends StatelessWidget {
  const MusicFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.selectedBackgroundColor,
    this.unselectedBackgroundColor,
    this.selectedBorderColor,
    this.unselectedBorderColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.horizontalPadding,
    this.verticalPadding,
    this.fontSize,
    this.borderWidth,
  });

  final String label;
  final bool isSelected;
  final Color? selectedBackgroundColor;
  final Color? unselectedBackgroundColor;
  final Color? selectedBorderColor;
  final Color? unselectedBorderColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final double? horizontalPadding;
  final double? verticalPadding;
  final double? fontSize;
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal:
            horizontalPadding ?? context.rs(12, min: 10, max: 13),
        vertical: verticalPadding ?? context.rs(6, min: 6, max: 7),
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? (selectedBackgroundColor ?? AppColors.primary)
            : (unselectedBackgroundColor ?? AppColors.white),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isSelected
              ? (selectedBorderColor ?? AppColors.primary)
              : (unselectedBorderColor ?? const Color(0xFFD9C9F0)),
          width: borderWidth ?? 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize ?? context.rs(11, min: 10.5, max: 12),
          fontWeight: FontWeight.w500,
          color: isSelected
              ? (selectedTextColor ?? AppColors.white)
              : (unselectedTextColor ?? AppColors.primary),
        ),
      ),
    );
  }
}
