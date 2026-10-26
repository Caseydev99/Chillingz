import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';

class SettingsOptionTile extends StatelessWidget {
  const SettingsOptionTile({
    super.key,
    required this.title,
    required this.iconPath,
    this.onTap,
    this.hasToggle = false,
    this.toggleValue = false,
    this.onToggleChanged,
    this.isDestructive = false,
  });

  final String title;
  final String iconPath;
  final VoidCallback? onTap;
  final bool hasToggle;
  final bool toggleValue;
  final ValueChanged<bool>? onToggleChanged;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final radius = context.rs(14, min: 13, max: 16);

    return Material(
      color: AppColors.settingsTileBackground,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.rs(14, min: 13, max: 16),
            vertical: context.rs(14, min: 13, max: 16),
          ),
          child: Row(
            children: [
              Container(
                width: context.rs(40, min: 38, max: 42),
                height: context.rs(40, min: 38, max: 42),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? const Color(0x33FF1F38)
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: context.rs(18, min: 17, max: 20),
                    height: context.rs(18, min: 17, max: 20),
                    colorFilter: ColorFilter.mode(
                      isDestructive
                          ? const Color(0xFFFF3146)
                          : AppColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              context.rs(12, min: 11, max: 14).hSpace,
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: context.rs(14.8, min: 14, max: 15.5),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (hasToggle)
                Transform.scale(
                  scale: 0.88,
                  child: Switch(
                    value: toggleValue,
                    activeColor: AppColors.primary,
                    activeTrackColor: AppColors.primaryLight,
                    inactiveThumbColor: AppColors.white,
                    inactiveTrackColor: const Color(0xFFD7D7DD),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: onToggleChanged,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: context.rs(24, min: 22, max: 26),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
