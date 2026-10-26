import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/text_styles.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(
            fontSize: 34,
            color: AppColors.authTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(
            color: AppColors.authTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
