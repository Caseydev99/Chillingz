import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

import '../core/constants/app_colors.dart';
import '../core/constants/app_images.dart';
import '../core/constants/app_strings.dart';
import '../core/services/location_permission_controller.dart';
import '../core/utils/extensions.dart';
import '../core/utils/helpers.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/profile/providers/profile_provider.dart';
import '../routes/app_routes.dart';
import 'app_logo.dart';
import 'profile_summary_card.dart';
import 'settings_mood_chip.dart';
import 'settings_option_tile.dart';

class ProfileSettingsView extends StatefulWidget {
  const ProfileSettingsView({super.key});

  @override
  State<ProfileSettingsView> createState() => _ProfileSettingsViewState();
}

class _ProfileSettingsViewState extends State<ProfileSettingsView> {
  String? _profileStreamUid;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStreamFor(
    String? uid,
  ) {
    if (uid == null) {
      _profileStreamUid = null;
      _profileStream = null;
      return null;
    }
    if (_profileStreamUid != uid) {
      _profileStreamUid = uid;
      _profileStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots();
    }
    return _profileStream;
  }

  @override
  Widget build(BuildContext context) {
    return Selector2<
      ProfileProvider,
      AuthProvider,
      ({
        User? user,
        String profileName,
        String profileEmail,
        String? avatarDataUrl,
        bool isAuthLoading,
      })
    >(
      selector: (context, profileProvider, authProvider) => (
        user: authProvider.currentUser,
        profileName: profileProvider.profileName,
        profileEmail: profileProvider.profileEmail.trim(),
        avatarDataUrl: profileProvider.selectedAvatarDataUrl,
        isAuthLoading: authProvider.isLoading,
      ),
      builder: (context, viewData, child) {
        final user = viewData.user;
        final localEmail = viewData.profileEmail;
        final provider = context.read<ProfileProvider>();
        final authProvider = context.read<AuthProvider>();
        final horizontalInset = context.screenWidth >= 410
            ? 10.0
            : context.screenWidth >= 390
            ? 12.0
            : 14.0;

        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalInset,
            context.rs(6, min: 4, max: 8),
            horizontalInset,
            context.rs(24, min: 22, max: 28),
          ),
          children: [
            const Center(child: AppLogo(height: 94)),
            context.rs(6, min: 4, max: 8).vSpace,
            Center(
              child: Text(
                AppStrings.settingsTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.rs(16, min: 15, max: 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            context.rs(12, min: 10, max: 12).vSpace,
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _profileStreamFor(user?.uid),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final firestoreName = data?['name']?.toString().trim() ?? '';
                final firestoreEmail = data?['email']?.toString().trim() ?? '';
                final firestoreAvatar =
                    data?['avatarUrl']?.toString().trim() ?? '';
                final profileName = firestoreName.isNotEmpty
                    ? firestoreName
                    : user?.displayName?.trim().isNotEmpty == true
                    ? user!.displayName!
                    : viewData.profileName;
                final profileEmail = firestoreEmail.isNotEmpty
                    ? firestoreEmail
                    : localEmail != AppStrings.editProfileEmail
                    ? localEmail
                    : user?.email ?? viewData.profileEmail;
                final avatarSource = viewData.avatarDataUrl?.isNotEmpty == true
                    ? viewData.avatarDataUrl!
                    : firestoreAvatar.isNotEmpty
                    ? firestoreAvatar
                    : AppImages.savedPicTwo;

                return ProfileSummaryCard(
                  name: profileName,
                  email: profileEmail,
                  avatarSource: avatarSource,
                );
              },
            ),
            context.rs(10, min: 8, max: 10).vSpace,
            _buildMoodSection(context),
            context.rs(14, min: 12, max: 14).vSpace,
            _buildSettingsLabel(context),
            context.rs(8, min: 6, max: 8).vSpace,
            ...provider.settingItems.map(
              (item) => _buildSettingsTile(
                context: context,
                title: item.title,
                iconPath: item.iconPath,
                routeName: item.routeName,
                hasToggle: item.hasToggle,
              ),
            ),
            context.rs(8, min: 8, max: 10).vSpace,
            SettingsOptionTile(
              title: AppStrings.deleteAccount,
              iconPath: provider.logoutIconPath,
              isDestructive: true,
              onTap: viewData.isAuthLoading
                  ? null
                  : () => _deleteAccount(context, authProvider),
            ),
            context.rs(10, min: 9, max: 11).vSpace,
            SettingsOptionTile(
              title: AppStrings.logout,
              iconPath: provider.logoutIconPath,
              isDestructive: true,
              onTap: viewData.isAuthLoading
                  ? null
                  : () => _signOut(context, authProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMoodSection(BuildContext context) {
    // Keep mood updates inside this small subtree. Rebuilding the whole
    // profile screen would recreate the avatar image and cause a visible
    // loading blink whenever a mood is selected.
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.chooseMood,
              style: TextStyle(
                fontSize: context.rs(10, min: 9.5, max: 10.5),
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
            context.rs(8, min: 7, max: 10).vSpace,
            Wrap(
              spacing: context.rs(8, min: 8, max: 10),
              runSpacing: context.rs(8, min: 8, max: 10),
              children: provider.moodOptions.map((mood) {
                return SettingsMoodChip(
                  label: mood,
                  isSelected: provider.selectedMood == mood,
                  onTap: () => provider.updateMood(mood),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  /// Sends the user to the OS settings. On return, the controller refreshes
  /// the toggle and Home location label without showing another prompt.
  Future<void> _openLocationSettings(BuildContext context) {
    return context
        .read<LocationPermissionController>()
        .openLocationPreferences();
  }

  Widget _buildSettingsLabel(BuildContext context) {
    return Text(
      AppStrings.settingsLabel,
      style: TextStyle(
        fontSize: context.rs(9.5, min: 9, max: 10),
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required String title,
    required String iconPath,
    required bool hasToggle,
    String? routeName,
  }) {
    // The location tile mirrors the real OS permission, so it rebuilds as soon
    // as the user changes it from the system settings.
    final hasLocationAccess = hasToggle
        ? context.select<LocationPermissionController, bool>(
            (controller) => controller.hasLocationAccess,
          )
        : false;

    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(10, min: 9, max: 11)),
      child: SettingsOptionTile(
        title: title,
        iconPath: iconPath,
        hasToggle: hasToggle,
        toggleValue: hasLocationAccess,
        onToggleChanged: hasToggle
            ? (_) => _openLocationSettings(context)
            : null,
        onTap: hasToggle
            ? () => _openLocationSettings(context)
            : routeName == null
            ? null
            : () => Navigator.pushNamed(context, routeName),
      ),
    );
  }

  Future<void> _deleteAccount(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final usesPassword =
        authProvider.currentUser?.providerData.any(
          (provider) => provider.providerId == 'password',
        ) ??
        false;

    // Verification is compulsory for every authentication method. Password
    // users re-enter their password; social-login users type DELETE.
    final verification = await _requestDeleteVerification(
      context,
      usesPassword: usesPassword,
    );
    if (verification == null || !context.mounted) {
      return;
    }

    // Let the verification route finish unmounting before presenting another
    // dialog. Opening the final dialog during the previous route's teardown
    // can trip Flutter's inherited-dependency assertion on real devices.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!context.mounted) {
      return;
    }

    final shouldDelete = await _requestFinalDeleteConfirmation(context);
    if (shouldDelete != true || !context.mounted) {
      return;
    }

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 16),
                Expanded(child: Text('Deleting your account...')),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await authProvider.deleteAccount(
        password: usesPassword ? verification : null,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      rootNavigator.pop();
      AppHelpers.showSnackBar(context, authProvider.authErrorMessage(error));
      return;
    }

    if (!context.mounted) {
      return;
    }

    rootNavigator.pop();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<String?> _requestDeleteVerification(
    BuildContext context, {
    required bool usesPassword,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) =>
          DeleteAccountVerificationDialog(usesPassword: usesPassword),
    );
  }

  Future<bool?> _requestFinalDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const DeleteAccountFinalConfirmationDialog(),
    );
  }

  Future<void> _signOut(BuildContext context, AuthProvider authProvider) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Logout',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await authProvider.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }
}

class DeleteAccountVerificationDialog extends StatefulWidget {
  const DeleteAccountVerificationDialog({
    super.key,
    required this.usesPassword,
  });

  final bool usesPassword;

  @override
  State<DeleteAccountVerificationDialog> createState() =>
      _DeleteVerificationDialogState();
}

class _DeleteVerificationDialogState
    extends State<DeleteAccountVerificationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscurePassword = true;
  bool _understandsDeletion = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enteredValue = _controller.text.trim();
    final hasValidEntry = widget.usesPassword
        ? enteredValue.isNotEmpty
        : enteredValue == 'DELETE';
    final canContinue = hasValidEntry && _understandsDeletion;

    return AlertDialog(
      title: const Text('Verify account deletion'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.usesPassword
                  ? 'Enter your current password to continue.'
                  : 'Type DELETE below to continue.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: widget.usesPassword && _obscurePassword,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: widget.usesPassword
                  ? TextCapitalization.none
                  : TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: widget.usesPassword
                    ? 'Current password'
                    : 'Type DELETE',
                suffixIcon: widget.usesPassword
                    ? IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _understandsDeletion,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'I understand that this permanently deletes my account.',
              ),
              onChanged: (value) =>
                  setState(() => _understandsDeletion = value ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: canContinue
              ? () {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context, enteredValue);
                }
              : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class DeleteAccountFinalConfirmationDialog extends StatelessWidget {
  const DeleteAccountFinalConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: AppColors.error,
        size: 36,
      ),
      title: const Text('Permanently delete account?'),
      content: const Text(
        "This can't be undone. Your account and saved profile data will "
        'be permanently removed. Are you absolutely sure?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep my account'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete permanently'),
        ),
      ],
    );
  }
}
