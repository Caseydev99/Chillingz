import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/extensions.dart';
import '../core/utils/helpers.dart';
import '../core/widgets/custom_button.dart';
import '../routes/app_routes.dart';
import '../features/auth/providers/auth_provider.dart';
import 'otp_digit_field.dart';

class VerificationCodeForm extends StatefulWidget {
  const VerificationCodeForm({super.key});

  @override
  State<VerificationCodeForm> createState() => _VerificationCodeFormState();
}

class _VerificationCodeFormState extends State<VerificationCodeForm> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((controller) => controller.text).join();

  void _handleCodeChange(String value, int index) {
    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _submit(AuthProvider provider) async {
    if (_otpCode.length < 4) {
      AppHelpers.showSnackBar(context, AppStrings.verificationCodeError);
      return;
    }

    await provider.verifyCode();

    if (!mounted) {
      return;
    }

    Navigator.pushNamed(context, AppRoutes.resetPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            18.vSpace,
            Text(
              AppStrings.verificationSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.authTextSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            6.vSpace,
            const Text(
              AppStrings.verificationEmail,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
            30.vSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rs(5, min: 4, max: 6),
                  ),
                  child: OtpDigitField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) => _handleCodeChange(value, index),
                  ),
                ),
              ),
            ),
            24.vSpace,
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.authTextSecondary,
                    ),
                children: const [
                  TextSpan(text: AppStrings.didNotReceiveCode),
                  TextSpan(
                    text: AppStrings.resendCode,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            34.vSpace,
            CustomButton(
              label: AppStrings.confirm,
              isLoading: provider.isLoading,
              onPressed: () => _submit(provider),
            ),
          ],
        );
      },
    );
  }
}
