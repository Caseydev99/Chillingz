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

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider provider) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    try {
      await provider.signIn(
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

    AppHelpers.showSnackBar(context, 'Signed in successfully.');
    Navigator.pushReplacementNamed(context, AppRoutes.bottomNav);
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
                obscureText: provider.obscureSignInPassword,
                validator: AppValidators.password,
                suffixIcon: IconButton(
                  onPressed: provider.toggleSignInPasswordVisibility,
                  icon: Icon(
                    provider.obscureSignInPassword
                        ? AppIcons.visibility
                        : Icons.visibility_outlined,
                    color: const Color(0xFF8D8D8D),
                  ),
                ),
              ),
              16.vSpace,
              Row(
                children: [
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: Checkbox(
                      value: provider.stayLoggedIn,
                      onChanged: provider.toggleStayLoggedIn,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.stayLoggedIn,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.authTextSecondary,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.forgotPassword,
                        arguments: _emailController.text.trim(),
                      );
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
                ],
              ),
              36.vSpace,
              CustomButton(
                label: AppStrings.signIn,
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
                    Navigator.pushNamed(context, AppRoutes.signUp);
                  },
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.authTextSecondary,
                          ),
                      children: const [
                        TextSpan(text: AppStrings.notRegistered),
                        TextSpan(
                          text: AppStrings.signUpNow,
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
