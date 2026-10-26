import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/auth_header.dart';
import '../../../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topSpacing = context.rs(44, min: 36, max: 56);

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppValues.screenHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topSpacing),
              const Center(
                child: AuthHeader(
                  title: AppStrings.signIn,
                  subtitle: AppStrings.signInSubtitle,
                ),
              ),
              44.vSpace,
              const LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}
