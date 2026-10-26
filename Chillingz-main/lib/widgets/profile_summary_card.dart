import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';
import '../core/widgets/app_image.dart';

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.name,
    required this.email,
    required this.avatarSource,
  });

  final String name;
  final String email;
  final String avatarSource;

  @override
  Widget build(BuildContext context) {
    final cardHeight = context.rs(156, min: 150, max: 160);
    final radius = context.rs(16, min: 16, max: 18);
    final showAvatarPlaceholder = _shouldShowAvatarPlaceholder(avatarSource);

    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: AppColors.settingsProfileGradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          context.rs(24, min: 20, max: 24),
          context.rs(16, min: 15, max: 16),
          context.rs(24, min: 20, max: 24),
          context.rs(16, min: 15, max: 16),
        ),
        decoration: BoxDecoration(
          gradient: AppColors.settingsProfileOverlayGradient,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: context.rs(26, min: 24, max: 28),
              backgroundColor: AppColors.white,
              child: CircleAvatar(
                radius: context.rs(24, min: 22, max: 26),
                backgroundColor: AppColors.inputFill,
                child: showAvatarPlaceholder
                    ? Icon(
                        Icons.person_outline_rounded,
                        size: context.rs(28, min: 26, max: 30),
                        color: AppColors.primary,
                      )
                    : ClipOval(
                        child: AppImage(
                          source: avatarSource,
                          width: context.rs(48, min: 44, max: 52),
                          height: context.rs(48, min: 44, max: 52),
                        ),
                      ),
              ),
            ),
            context.rs(12, min: 10, max: 14).vSpace,
            Text(
              name,
              style: TextStyle(
                fontSize: context.rs(14, min: 13.5, max: 14),
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            context.rs(4, min: 4, max: 5).vSpace,
            Text(
              email,
              style: TextStyle(
                fontSize: context.rs(10.5, min: 10, max: 10.5),
                fontWeight: FontWeight.w400,
                color: const Color(0xD9FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _shouldShowAvatarPlaceholder(String value) {
    final source = value.trim();
    return source.isEmpty || source.contains('i.pravatar.cc');
  }
}
