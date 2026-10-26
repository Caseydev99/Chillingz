import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/constants/app_images.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/extensions.dart';

class SavedSearchBar extends StatelessWidget {
  const SavedSearchBar({
    super.key,
    this.height,
    this.iconSize,
    this.filterButtonSize,
    this.filterIconSize,
    this.hintText,
    this.controller,
    this.onChanged,
    this.backgroundColor,
    this.searchIconColor,
    this.hintColor,
    this.textColor,
    this.filterButtonColor,
    this.filterIconColor,
    this.borderRadius,
    this.leftPadding,
    this.rightPadding,
    this.onFilterTap,
  });

  final double? height;
  final double? iconSize;
  final double? filterButtonSize;
  final double? filterIconSize;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Color? backgroundColor;
  final Color? searchIconColor;
  final Color? hintColor;
  final Color? textColor;
  final Color? filterButtonColor;
  final Color? filterIconColor;
  final double? borderRadius;
  final double? leftPadding;
  final double? rightPadding;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    final resolvedHeight = height ?? context.rs(52, min: 50, max: 54);
    final resolvedIconSize = iconSize ?? context.rs(26, min: 24, max: 28);
    final resolvedFilterButtonSize =
        filterButtonSize ?? context.rs(40, min: 38, max: 42);
    final resolvedFilterIconSize =
        filterIconSize ?? context.rs(18, min: 17, max: 19);
    final resolvedSearchIconColor = searchIconColor ??
        (AppColors.isLightMode ? AppColors.primary : AppColors.white);
    final resolvedHintColor = hintColor ??
        (AppColors.isLightMode
            ? AppColors.textSecondary
            : AppColors.white.withValues(alpha: 0.7));
    final resolvedTextColor =
        textColor ?? (AppColors.isLightMode ? AppColors.black : AppColors.textPrimary);

    return Container(
      height: resolvedHeight,
      padding: EdgeInsets.only(
        left: leftPadding ?? context.rs(16, min: 15, max: 17),
        right: rightPadding ?? context.rs(10, min: 9, max: 11),
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.inputFill,
        borderRadius: BorderRadius.circular(
          borderRadius ?? context.rs(26, min: 25, max: 27),
        ),
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.search,
            size: resolvedIconSize,
            color: resolvedSearchIconColor,
          ),
          context.rs(8, min: 8, max: 10).hSpace,
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: context.rs(10.5, min: 10, max: 12),
                fontWeight: FontWeight.w400,
                color: resolvedTextColor,
              ),
              cursorColor: filterIconColor ?? AppColors.primary,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText ?? AppStrings.searchSaved,
                hintStyle: TextStyle(
                  fontSize: context.rs(10.5, min: 10, max: 12),
                  fontWeight: FontWeight.w400,
                  color: resolvedHintColor,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              width: resolvedFilterButtonSize,
              height: resolvedFilterButtonSize,
              decoration: BoxDecoration(
                color: filterButtonColor ?? AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  AppImages.filterIcon,
                  width: resolvedFilterIconSize,
                  height: resolvedFilterIconSize,
                  colorFilter: ColorFilter.mode(
                    filterIconColor ?? AppColors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
