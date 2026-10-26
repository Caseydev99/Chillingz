import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/appearance_option_tile.dart';
import '../../../widgets/app_screen_header.dart';
import '../../bottom_nav/providers/bottom_nav_provider.dart';
import '../providers/profile_provider.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  bool _isSaving = false;

  Future<void> _saveAndGoHome(BuildContext context) async {
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!context.mounted) {
      return;
    }

    context.read<BottomNavProvider>().resetToHome();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.bottomNav,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppValues.screenHorizontalPadding,
              ),
              child: Column(
                children: [
                  8.vSpace,
                  const AppScreenHeader(title: AppStrings.appearance),
                  16.vSpace,
                  AppearanceOptionTile(
                    title: AppStrings.dark,
                    icon: Icons.dark_mode_outlined,
                    isSelected: provider.selectedAppearance == AppStrings.dark,
                    onTap: () => provider.updateAppearance(AppStrings.dark),
                  ),
                  10.vSpace,
                  AppearanceOptionTile(
                    title: AppStrings.light,
                    icon: Icons.light_mode_outlined,
                    isSelected: provider.selectedAppearance == AppStrings.light,
                    onTap: () => provider.updateAppearance(AppStrings.light),
                  ),
                  10.vSpace,
                  AppearanceOptionTile(
                    title: AppStrings.system,
                    icon: Icons.phone_iphone_outlined,
                    isSelected:
                        provider.selectedAppearance == AppStrings.system,
                    onTap: () => provider.updateAppearance(AppStrings.system),
                  ),
                  const Spacer(),
                  CustomButton(
                    label: AppStrings.save,
                    isLoading: _isSaving,
                    onPressed: () => _saveAndGoHome(context),
                  ),
                  20.vSpace,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
