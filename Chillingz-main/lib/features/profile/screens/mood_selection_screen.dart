import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../widgets/app_screen_header.dart';
import '../../../widgets/appearance_option_tile.dart';
import '../providers/profile_provider.dart';

class MoodSelectionScreen extends StatelessWidget {
  const MoodSelectionScreen({super.key});

  String _emojiForMood(String mood) {
    switch (mood) {
      case AppStrings.relaxed:
        return '\u{1F60C}';
      case AppStrings.energetic:
        return '\u{26A1}';
      case AppStrings.spontaneous:
        return '\u{1F500}';
      default:
        return '\u{1F642}';
    }
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
                  const AppScreenHeader(title: AppStrings.moodSelection),
                  16.vSpace,
                  ...provider.moodOptions.map((mood) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: context.rs(10, min: 9, max: 11),
                      ),
                      child: AppearanceOptionTile(
                        title: mood,
                        leadingEmoji: _emojiForMood(mood),
                        isSelected: provider.selectedMood == mood,
                        onTap: () => provider.updateMood(mood),
                      ),
                    );
                  }),
                  const Spacer(),
                  CustomButton(
                    label: AppStrings.save,
                    onPressed: () => Navigator.pop(context),
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
