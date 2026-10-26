import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/extensions.dart';

class HomeTabs extends StatelessWidget {
  const HomeTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.rs(2, min: 0, max: 4)),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: AppStrings.categories,
              isSelected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: AppStrings.chillingzForYou,
              isSelected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.rs(14.5, min: 13.5, max: 15.5),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          context.rs(8, min: 7, max: 9).vSpace,
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 1.1,
                color: AppColors.border,
              ),
              if (isSelected)
                Align(
                  child: Container(
                    width: context.rs(104, min: 86, max: 118),
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
