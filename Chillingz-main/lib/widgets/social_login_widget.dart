import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';
import '../core/utils/helpers.dart';
import '../features/auth/providers/auth_provider.dart';
import '../routes/app_routes.dart';

/// "or" divider plus a "Continue with Google" button for the login and
/// sign-up forms. Renders nothing on platforms where Google sign-in isn't
/// configured yet (see `GoogleSignInConfig`).
class SocialLoginWidget extends StatelessWidget {
  const SocialLoginWidget({super.key, this.requireTermsAgreement = false});

  /// On the sign-up form the terms checkbox must be ticked first, the same
  /// as for an email sign-up.
  final bool requireTermsAgreement;

  static const String _googleLogo =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">'
      '<path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.6 5.4 2.7 13.3l7.9 6.1C12.5 13.6 17.8 9.5 24 9.5z"/>'
      '<path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.7 6c4.5-4.2 6.9-10.3 6.9-17.7z"/>'
      '<path fill="#FBBC05" d="M10.6 28.6A14.5 14.5 0 019.5 24c0-1.6.3-3.2.8-4.6l-7.9-6.1A24 24 0 000 24c0 3.9.9 7.5 2.7 10.7l7.9-6.1z"/>'
      '<path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.7-6c-2.2 1.5-5 2.3-8.2 2.3-6.2 0-11.5-4.1-13.4-9.9l-7.9 6.1C6.6 42.6 14.6 48 24 48z"/>'
      '</svg>';

  Future<void> _signIn(BuildContext context, AuthProvider provider) async {
    if (requireTermsAgreement && !provider.agreeToTerms) {
      AppHelpers.showSnackBar(
        context,
        'Please agree to the terms and conditions first.',
      );
      return;
    }

    final bool needsInterests;
    try {
      needsInterests = await provider.signInWithGoogle();
    } on GoogleSignInCancelled {
      return;
    } catch (error) {
      if (context.mounted) {
        AppHelpers.showSnackBar(context, provider.authErrorMessage(error));
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    AppHelpers.showSnackBar(context, 'Signed in successfully.');
    Navigator.pushNamedAndRemoveUntil(
      context,
      needsInterests ? AppRoutes.onboarding : AppRoutes.bottomNav,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    if (!provider.isGoogleSignInAvailable) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final dividerColor = AppColors.authTextSecondary.withValues(alpha: 0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        20.vSpace,
        Row(
          children: [
            Expanded(child: Divider(color: dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.authTextSecondary,
                ),
              ),
            ),
            Expanded(child: Divider(color: dividerColor)),
          ],
        ),
        20.vSpace,
        OutlinedButton.icon(
          onPressed: provider.isLoading
              ? null
              : () => _signIn(context, provider),
          icon: SvgPicture.string(_googleLogo, width: 20, height: 20),
          label: const Text('Continue with Google'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1F1F1F),
            side: const BorderSide(color: Color(0xFFDADCE0)),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (!requireTermsAgreement) ...[
          8.vSpace,
          Text(
            'New here? Continuing with Google creates your account and means '
            'you agree to our Terms & Conditions.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.authTextSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
