import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/text_styles.dart';

class AppHelpers {
  const AppHelpers._();

  static void showSnackBar(BuildContext context, String message) {
    final isError =
        message.toLowerCase().contains('error') ||
        message.toLowerCase().contains('invalid') ||
        message.toLowerCase().contains('incorrect') ||
        message.toLowerCase().contains('failed') ||
        message.toLowerCase().contains('try again');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          elevation: 10,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          backgroundColor: AppColors.isLightMode
              ? AppColors.white
              : const Color(0xFF321047),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isError
                  ? AppColors.error.withValues(alpha: 0.35)
                  : AppColors.primary.withValues(alpha: 0.28),
            ),
          ),
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isError
                      ? AppColors.error.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.error_outline_rounded : Icons.check_rounded,
                  color: isError ? AppColors.error : AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
