import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../navigation/app_navigator.dart';

/// Central prompt used when a signed-out guest selects an account-only action.
class AccountAccessPrompt {
  const AccountAccessPrompt._();

  static bool _isVisible = false;

  static Future<void> show([BuildContext? context]) async {
    if (_isVisible) {
      return;
    }

    final promptContext = context ?? appNavigatorKey.currentContext;
    if (promptContext == null || !promptContext.mounted) {
      return;
    }

    _isVisible = true;
    try {
      final routeName = await showDialog<String>(
        context: promptContext,
        useRootNavigator: true,
        builder: (dialogContext) => AlertDialog(
          title: const Text(AppStrings.accountRequiredTitle),
          content: const Text(AppStrings.accountRequiredMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, AppRoutes.signUp),
              child: const Text('Create Account'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, AppRoutes.login),
              child: const Text(
                'Log In',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );

      if (routeName != null) {
        appNavigatorKey.currentState?.pushNamed(routeName);
      }
    } finally {
      _isVisible = false;
    }
  }
}
