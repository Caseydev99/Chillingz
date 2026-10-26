import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/app_image.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_screen_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bottom_nav/providers/bottom_nav_provider.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadCurrentProfile();
    });
  }

  Future<void> _loadCurrentProfile() async {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final user = authProvider.currentUser;
    if (user == null) {
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) {
      return;
    }

    final data = snapshot.data();
    profileProvider.updateProfileFields(
      name: data?['name']?.toString() ?? user.displayName ?? '',
      email: data?['email']?.toString() ?? user.email ?? '',
      avatarDataUrl: data?['avatarUrl']?.toString(),
    );
  }

  Future<void> _pickAvatar(ProfileProvider profileProvider) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 72,
    );
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    final mimeType = image.mimeType ?? 'image/jpeg';
    profileProvider.updateAvatarDataUrl(
      'data:$mimeType;base64,${base64Encode(bytes)}',
    );
  }

  Future<void> _saveProfile(
    ProfileProvider profileProvider,
    AuthProvider authProvider,
  ) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    try {
      await authProvider.updateUserProfile(
        name: profileProvider.nameController.text,
        email: profileProvider.emailController.text,
        avatarDataUrl: profileProvider.selectedAvatarDataUrl,
      );
      profileProvider.updateProfileFields(
        name: profileProvider.nameController.text,
        email: profileProvider.emailController.text,
        avatarDataUrl: profileProvider.selectedAvatarDataUrl,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      AppHelpers.showSnackBar(context, authProvider.authErrorMessage(error));
      return;
    }

    if (!mounted) {
      return;
    }

    AppHelpers.showSnackBar(context, 'Profile updated successfully.');
    context.read<BottomNavProvider>().updateIndex(0);
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.bottomNav, (_) => false);
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
                              title: AppStrings.editProfileTitle,
                            ),
                            14.vSpace,
                            _AvatarPicker(
                              provider: provider,
                              authProvider: authProvider,
                              onTap: () => _pickAvatar(provider),
                            ),
                            22.vSpace,
                            Text(
                              AppStrings.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize:
                                        context.rs(11, min: 10.5, max: 12),
                                  ),
                            ),
                            8.vSpace,
                            CustomTextField(
                              controller: provider.nameController,
                              hintText: AppStrings.editProfileName,
                              validator: AppValidators.name,
                            ),
                            18.vSpace,
                            Text(
                              AppStrings.emailAddress,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize:
                                        context.rs(11, min: 10.5, max: 12),
                                  ),
                            ),
                            8.vSpace,
                            CustomTextField(
                              controller: provider.emailController,
                              hintText: AppStrings.editProfileEmail,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true,
                              suffixIcon: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF8D8D8D),
                              ),
                            ),
                            const Spacer(),
                            CustomButton(
                              label: AppStrings.save,
                              isLoading: authProvider.isLoading,
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _saveProfile(provider, authProvider),
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

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.provider,
    required this.authProvider,
    required this.onTap,
  });

  final ProfileProvider provider;
  final AuthProvider authProvider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = authProvider.currentUser;

    return Center(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: user == null
            ? null
            : FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
        builder: (context, snapshot) {
          final firestoreAvatar =
              snapshot.data?.data()?['avatarUrl']?.toString().trim() ?? '';
          final avatarSource =
              provider.selectedAvatarDataUrl?.isNotEmpty == true
                  ? provider.selectedAvatarDataUrl!
                  : firestoreAvatar.isNotEmpty
                      ? firestoreAvatar
                      : '';

          return GestureDetector(
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: context.rs(32, min: 30, max: 34),
                  backgroundColor: AppColors.white,
                  child: _shouldShowAvatarPlaceholder(avatarSource)
                      ? Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primary,
                          size: context.rs(34, min: 32, max: 36),
                        )
                      : ClipOval(
                          child: AppImage(
                            source: avatarSource,
                            width: context.rs(60, min: 56, max: 64),
                            height: context.rs(60, min: 56, max: 64),
                          ),
                        ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: context.rs(24, min: 22, max: 26),
                    height: context.rs(24, min: 22, max: 26),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8A4AD8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: context.rs(13, min: 12, max: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static bool _shouldShowAvatarPlaceholder(String value) {
    final source = value.trim();
    return source.isEmpty || source.contains('i.pravatar.cc');
  }
}
