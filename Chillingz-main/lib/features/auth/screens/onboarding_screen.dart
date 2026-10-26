import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/onboarding_interest_wrap.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _handleInterestTap(
    BuildContext context,
    AuthProvider provider,
    String interest,
  ) {
    final errorMessage = provider.updateInterestSelection(interest);
    if (errorMessage == null) {
      return;
    }

    AppHelpers.showSnackBar(context, errorMessage);
  }

  Future<void> _handleConfirm(
    BuildContext context,
    AuthProvider provider,
  ) async {
    if (provider.selectedInterests.length < AuthProvider.minInterestSelection) {
      AppHelpers.showSnackBar(
        context,
        AppStrings.interestSelectionLimitMessage,
      );
      return;
    }

    await provider.saveSelectedInterests();

    if (!context.mounted) {
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.bottomNav);
  }

  @override
  Widget build(BuildContext context) {
    final topSpacing = context.isSmallPhone ? 26.0 : 38.0;

    return Consumer<AuthProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppColors.authBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppValues.screenHorizontalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      context.screenHeight - MediaQuery.paddingOf(context).top,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _handleConfirm(context, provider),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          AppStrings.skip,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: topSpacing),
                    Text(
                      AppStrings.onboardingTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        height: 22 / 18,
                        letterSpacing: 0,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                    18.vSpace,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        AppStrings.onboardingSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    ),
                    24.vSpace,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OnboardingInterestWrap(
                        items: provider.interestOptions,
                        isSelected: provider.isInterestSelected,
                        onTap: (interest) =>
                            _handleInterestTap(context, provider, interest),
                      ),
                    ),
                    32.vSpace,
                    CustomButton(
                      label: AppStrings.confirm,
                      isLoading: provider.isLoading,
                      onPressed: provider.isLoading
                          ? null
                          : () => _handleConfirm(context, provider),
                    ),
                    24.vSpace,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
