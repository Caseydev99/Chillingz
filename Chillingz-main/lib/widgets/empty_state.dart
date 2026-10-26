import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.topPadding,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double? topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: topPadding ?? context.rs(28, min: 24, max: 36),
        bottom: context.rs(18, min: 16, max: 22),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.rs(54, min: 50, max: 60),
              height: context.rs(54, min: 50, max: 60),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: context.rs(26, min: 24, max: 30),
              ),
            ),
            context.rs(12, min: 10, max: 14).vSpace,
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: context.rs(14, min: 13, max: 15),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              context.rs(12, min: 10, max: 14).vSpace,
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rs(14, min: 12, max: 16),
                    vertical: context.rs(8, min: 7, max: 9),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
