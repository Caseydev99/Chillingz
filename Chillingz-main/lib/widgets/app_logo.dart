import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_images.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/extensions.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    final resolvedHeight = height ?? 94;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    final logo = Image.asset(
      AppImages.appLogo,
      height: resolvedHeight,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          AppImages.legacyAppLogo,
          height: resolvedHeight,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: context.rs(26, min: 24, max: 30),
                  fontWeight: FontWeight.w700,
                  color: isLightMode
                      ? AppColors.darkBackgroundBase
                      : AppColors.primary,
                ),
              ),
            );
          },
        );
      },
    );

    if (!isLightMode) {
      return logo;
    }

    // The source artwork contains very light lettering. In light mode use a
    // clean, single-colour brand mark so it stays legible without placing a
    // box or background plate behind the logo.
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(
        AppColors.darkBackgroundBase,
        BlendMode.srcIn,
      ),
      child: logo,
    );
  }
}
