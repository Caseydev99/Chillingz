import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';

class SavedSectionTitle extends StatelessWidget {
  const SavedSectionTitle({
    super.key,
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
  });

  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: context.rs(18, min: 17, max: 19),
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailingLabel != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailingLabel!,
              style: TextStyle(
                fontSize: context.rs(11.5, min: 11, max: 12),
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
