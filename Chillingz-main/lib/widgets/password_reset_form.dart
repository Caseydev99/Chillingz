import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/extensions.dart';
import '../core/utils/validators.dart';
import '../core/widgets/custom_button.dart';
import '../core/widgets/custom_text_field.dart';
import '../features/auth/providers/auth_provider.dart';
import 'password_reset_success_sheet.dart';

class PasswordResetForm extends StatefulWidget {
  const PasswordResetForm({super.key});

  @override
  State<PasswordResetForm> createState() => _PasswordResetFormState();
}

class _PasswordResetFormState extends State<PasswordResetForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider provider) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    await provider.resetPassword();

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const PasswordResetSuccessSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, provider, child) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              18.vSpace,
              Text(
                AppStrings.newPassword,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.authTextPrimary,
                    ),
              ),
              8.vSpace,
              CustomTextField(
                controller: _passwordController,
                hintText: AppStrings.newPasswordHint,
                obscureText: provider.obscureResetPassword,
                validator: AppValidators.password,
                suffixIcon: IconButton(
                  onPressed: provider.toggleResetPasswordVisibility,
                  icon: Icon(
                    provider.obscureResetPassword
                        ? AppIcons.visibility
                        : Icons.visibility_outlined,
                    color: const Color(0xFF8D8D8D),
                  ),
                ),
              ),
              16.vSpace,
              Text(
                AppStrings.confirmPassword,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.authTextPrimary,
                    ),
              ),
              8.vSpace,
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: AppStrings.confirmPasswordHint,
                obscureText: provider.obscureResetConfirmPassword,
                validator: (value) => AppValidators.confirmPassword(
                  value,
                  _passwordController.text,
                ),
                suffixIcon: IconButton(
                  onPressed: provider.toggleResetConfirmPasswordVisibility,
                  icon: Icon(
                    provider.obscureResetConfirmPassword
                        ? AppIcons.visibility
                        : Icons.visibility_outlined,
                    color: const Color(0xFF8D8D8D),
                  ),
                ),
              ),
              34.vSpace,
              CustomButton(
                label: AppStrings.confirm,
                isLoading: provider.isLoading,
                onPressed: () => _submit(provider),
              ),
            ],
          ),
        );
      },
    );
  }
}
