import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_images.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/extensions.dart';
import '../core/widgets/custom_button.dart';
import '../routes/app_routes.dart';

class PasswordResetSuccessSheet extends StatelessWidget {
  const PasswordResetSuccessSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            26.vSpace,
            Image.asset(
              AppImages.verify,
              width: 86,
              height: 86,
              fit: BoxFit.contain,
            ),
            28.vSpace,
            Text(
              AppStrings.passwordResetSuccessfully,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            12.vSpace,
            Text(
              AppStrings.passwordResetMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.authTextSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            28.vSpace,
            CustomButton(
              label: AppStrings.backToLogin,
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.signUp,
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
