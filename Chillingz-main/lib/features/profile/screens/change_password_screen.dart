import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../widgets/app_screen_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isFinishingSuccessfully = false;

  Future<void> _submit(
    AuthProvider authProvider,
    ProfileProvider profileProvider,
  ) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      await authProvider.changePassword(
        currentPassword: profileProvider.currentPasswordController.text,
        newPassword: profileProvider.newPasswordController.text,
      );

      _isFinishingSuccessfully = true;
      _formKey.currentState?.reset();
      profileProvider.clearPasswordFields();

      if (!mounted) {
        return;
      }

      AppHelpers.showSnackBar(context, 'Password changed successfully.');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      AppHelpers.showSnackBar(context, authProvider.authErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProfileProvider, AuthProvider>(
      builder: (context, provider, authProvider, child) {
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppValues.screenHorizontalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            8.vSpace,
                            const AppScreenHeader(
                              title: AppStrings.changePasswordTitle,
                            ),
                            16.vSpace,
                            Text(
                              AppStrings.currentPasswordLabel,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: context.rs(
                                      11,
                                      min: 10.5,
                                      max: 12,
                                    ),
                                  ),
                            ),
                            8.vSpace,
                            CustomTextField(
                              controller: provider.currentPasswordController,
                              hintText: AppStrings.currentPasswordHint,
                              obscureText: provider.obscureCurrentPassword,
                              validator: (value) => _isFinishingSuccessfully
                                  ? null
                                  : AppValidators.password(value),
                              suffixIcon: IconButton(
                                onPressed:
                                    provider.toggleCurrentPasswordVisibility,
                                icon: Icon(
                                  provider.obscureCurrentPassword
                                      ? AppIcons.visibility
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF8D8D8D),
                                ),
                              ),
                            ),
                            16.vSpace,
                            Text(
                              AppStrings.newPassword,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: context.rs(
                                      11,
                                      min: 10.5,
                                      max: 12,
                                    ),
                                  ),
                            ),
                            8.vSpace,
                            CustomTextField(
                              controller: provider.newPasswordController,
                              hintText: AppStrings.newPasswordHint,
                              obscureText: provider.obscureNewPassword,
                              validator: (value) {
                                if (_isFinishingSuccessfully) {
                                  return null;
                                }
                                final error = AppValidators.password(value);
                                if (error != null) {
                                  return error;
                                }
                                if (value ==
                                    provider.currentPasswordController.text) {
                                  return 'New password must be different.';
                                }
                                return null;
                              },
                              suffixIcon: IconButton(
                                onPressed: provider.toggleNewPasswordVisibility,
                                icon: Icon(
                                  provider.obscureNewPassword
                                      ? AppIcons.visibility
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF8D8D8D),
                                ),
                              ),
                            ),
                            16.vSpace,
                            Text(
                              AppStrings.confirmPassword,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: context.rs(
                                      11,
                                      min: 10.5,
                                      max: 12,
                                    ),
                                  ),
                            ),
                            8.vSpace,
                            CustomTextField(
                              controller: provider.confirmPasswordController,
                              hintText: AppStrings.confirmPasswordHint,
                              obscureText: provider.obscureConfirmPassword,
                              validator: (value) => _isFinishingSuccessfully
                                  ? null
                                  : AppValidators.confirmPassword(
                                      value,
                                      provider.newPasswordController.text,
                                    ),
                              suffixIcon: IconButton(
                                onPressed:
                                    provider.toggleConfirmPasswordVisibility,
                                icon: Icon(
                                  provider.obscureConfirmPassword
                                      ? AppIcons.visibility
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF8D8D8D),
                                ),
                              ),
                            ),
                            const Spacer(),
                            CustomButton(
                              label: AppStrings.save,
                              isLoading: authProvider.isLoading,
                              onPressed: () => _submit(authProvider, provider),
                            ),
                            20.vSpace,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
