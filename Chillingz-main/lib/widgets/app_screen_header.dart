import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';
import 'app_logo.dart';

class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(child: AppLogo(height: 94)),
        context.rs(1, min: 0, max: 2).vSpace,
        SizedBox(
          height: context.rs(64, min: 60, max: 70),
          child: Row(
            children: [
              SizedBox(
                width: context.rs(62, min: 56, max: 68),
                height: double.infinity,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.primary,
                    size: context.rs(46, min: 42, max: 50),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rs(4, min: 2, max: 6),
                  ),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.rs(18, min: 17, max: 19),
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              // Mirrors the back-button width so the title stays visually
              // centered while remaining completely outside its tap area.
              SizedBox(width: context.rs(62, min: 56, max: 68)),
            ],
          ),
        ),
      ],
    );
  }
}
