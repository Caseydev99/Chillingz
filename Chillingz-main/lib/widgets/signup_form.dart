import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/extensions.dart';
import '../core/utils/helpers.dart';
import '../core/utils/validators.dart';
import '../core/widgets/custom_button.dart';
import '../core/widgets/custom_text_field.dart';
import '../routes/app_routes.dart';
import '../features/auth/providers/auth_provider.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider provider) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !provider.agreeToTerms) {
      if (!provider.agreeToTerms) {
        AppHelpers.showSnackBar(
          context,
          'Please agree to the terms and conditions first.',
        );
      }
      return;
    }

    try {
      await provider.signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      AppHelpers.showSnackBar(context, provider.authErrorMessage(error));
      return;
    }

    if (!mounted) {
      return;
    }

    AppHelpers.showSnackBar(context, 'Account created successfully.');
    Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
  }

  // Kept for the commented guest button below.
  // ignore: unused_element
  void _continueAsGuest(AuthProvider provider) {
    provider.continueAsGuest();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.bottomNav,
      (route) => false,
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
              Text(
                AppStrings.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.authTextPrimary,
                    ),
              ),
              8.vSpace,
              CustomTextField(
                controller: _nameController,
                hintText: AppStrings.nameHint,
                validator: AppValidators.name,
              ),
              20.vSpace,
              Text(
                AppStrings.email,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.authTextPrimary,
                    ),
              ),
              8.vSpace,
              CustomTextField(
                controller: _emailController,
                hintText: AppStrings.emailHint,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.email,
              ),
              20.vSpace,
              Text(
                AppStrings.password,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.authTextPrimary,
                    ),
              ),
              8.vSpace,
              CustomTextField(
                controller: _passwordController,
                hintText: AppStrings.passwordHint,
                obscureText: provider.obscureSignUpPassword,
                validator: AppValidators.password,
                suffixIcon: IconButton(
                  onPressed: provider.toggleSignUpPasswordVisibility,
                  icon: Icon(
                    provider.obscureSignUpPassword
                        ? AppIcons.visibility
                        : Icons.visibility_outlined,
                    color: const Color(0xFF8D8D8D),
                  ),
                ),
              ),
              16.vSpace,
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.forgotPassword);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7925C7),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    AppStrings.forgotPassword,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF7925C7),
                    ),
                  ),
                ),
              ),
              12.vSpace,
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: Checkbox(
                      value: provider.agreeToTerms,
                      onChanged: provider.toggleAgreeToTerms,
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.authTextSecondary,
                            ),
                        children: const [
                          TextSpan(text: AppStrings.agreeToTermsPrefix),
                          TextSpan(
                            text: AppStrings.termsAndConditions,
                            style: TextStyle(
                              color: Color(0xFF7925C7),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF7925C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              36.vSpace,
              CustomButton(
                label: AppStrings.createAccountButton,
                isLoading: provider.isLoading,
                onPressed: provider.isLoading ? null : () => _submit(provider),
              ),
              // TODO: re-enable guest flow once account-gating issue (5.1.1v)
              // is fully resolved.
              /*
              12.vSpace,
              OutlinedButton(
                onPressed: provider.isLoading
                    ? null
                    : () => _continueAsGuest(provider),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: const StadiumBorder(),
                ),
                child: const Text(AppStrings.continueAsGuest),
              ),
              */
              20.vSpace,
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.authTextSecondary,
                          ),
                      children: const [
                        TextSpan(text: AppStrings.alreadyHaveAccount),
                        TextSpan(
                          text: AppStrings.signInNow,
                          style: TextStyle(
                            color: Color(0xFF7925C7),
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF7925C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
