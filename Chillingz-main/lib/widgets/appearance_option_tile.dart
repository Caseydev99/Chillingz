import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';

class AppearanceOptionTile extends StatelessWidget {
  const AppearanceOptionTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.leadingEmoji,
  });

  final String title;
  final IconData? icon;
  final String? leadingEmoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.settingsTileBackground,
      borderRadius: BorderRadius.circular(context.rs(10, min: 10, max: 12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.rs(10, min: 10, max: 12)),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.rs(14, min: 13, max: 16),
            vertical: context.rs(12, min: 11, max: 13),
          ),
          child: Row(
            children: [
              if (leadingEmoji != null)
                Text(
                  leadingEmoji!,
                  style: TextStyle(
                    fontSize: context.rs(16, min: 15, max: 18),
                  ),
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: context.rs(18, min: 17, max: 20),
                  color: AppColors.textSecondary,
                ),
              context.rs(10, min: 9, max: 11).hSpace,
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: context.rs(13, min: 12.5, max: 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: context.rs(18, min: 17, max: 19),
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
