import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/auth_header.dart';
import '../../../widgets/signup_form.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topSpacing = context.isSmallPhone ? context.hp(8) : context.hp(11);

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
                  title: AppStrings.createYourAccount,
                  subtitle: AppStrings.signUpSubtitle,
                ),
              ),
              44.vSpace,
              const SignupForm(),
            ],
          ),
        ),
      ),
    );
  }
}
