import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../widgets/app_screen_header.dart';
import '../../../widgets/onboarding_interest_wrap.dart';
import '../../home/providers/home_provider.dart';
import '../providers/profile_provider.dart';

class InterestsSelectionScreen extends StatefulWidget {
  const InterestsSelectionScreen({super.key});

  @override
  State<InterestsSelectionScreen> createState() =>
      _InterestsSelectionScreenState();
}

class _InterestsSelectionScreenState extends State<InterestsSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ProfileProvider>().loadInterests();
    });
  }

  void _handleInterestTap(
    BuildContext context,
    ProfileProvider provider,
    String interest,
  ) {
    final errorMessage = provider.updateInterestSelection(interest);
    if (errorMessage == null) {
      return;
    }

    AppHelpers.showSnackBar(context, errorMessage);
  }

  Future<void> _handleSave(ProfileProvider provider) async {
    if (provider.selectedInterests.length <
        ProfileProvider.minInterestSelection) {
      AppHelpers.showSnackBar(
        context,
        AppStrings.interestSelectionLimitMessage,
      );
      return;
    }

    await provider.saveSelectedInterests();

    if (!mounted) {
      return;
    }

    await context.read<HomeProvider>().loadUserTags(forceRefresh: true);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  8.vSpace,
                  const AppScreenHeader(title: AppStrings.interestsSelection),
                  18.vSpace,
                  OnboardingInterestWrap(
                    items: provider.interestOptions,
                    isSelected: provider.isInterestSelected,
                    onTap: (interest) =>
                        _handleInterestTap(context, provider, interest),
                  ),
                  const Spacer(),
                  CustomButton(
                    label: AppStrings.save,
                    isLoading: provider.isLoadingInterests,
                    onPressed: provider.isLoadingInterests
                        ? null
                        : () => _handleSave(provider),
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
