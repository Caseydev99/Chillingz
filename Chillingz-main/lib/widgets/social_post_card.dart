import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';
import '../core/widgets/app_image.dart';
import '../features/home/models/social_post_item.dart';

class SocialPostCard extends StatelessWidget {
  const SocialPostCard({
    super.key,
    required this.item,
    this.imageHeight,
    this.borderRadius,
    this.headerBottomPadding,
    this.contentTopPadding,
    this.contentBottomPadding,
  });

  final SocialPostItem item;
  final double? imageHeight;
  final double? borderRadius;
  final double? headerBottomPadding;
  final double? contentTopPadding;
  final double? contentBottomPadding;

  @override
  Widget build(BuildContext context) {
    final resolvedRadius = borderRadius ?? context.rs(12, min: 12, max: 14);
    final primaryTextColor =
        AppColors.isLightMode ? AppColors.textPrimary : AppColors.white;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(resolvedRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.rs(12, min: 12, max: 14),
              context.rs(10, min: 10, max: 12),
              context.rs(12, min: 12, max: 14),
              headerBottomPadding ?? context.rs(8, min: 8, max: 10),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: AppImage(
                    source: item.avatarImagePath,
                    width: context.rs(32, min: 30, max: 34),
                    height: context.rs(32, min: 30, max: 34),
                    fit: BoxFit.cover,
                  ),
                ),
                context.rs(10, min: 9, max: 11).hSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.username,
                        style: TextStyle(
                          fontSize: context.rs(13, min: 12.5, max: 14),
                          fontWeight: FontWeight.w500,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        item.platform,
                        style: TextStyle(
                          fontSize: context.rs(10.5, min: 10, max: 11),
                          fontWeight: FontWeight.w400,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  item.platformIconPath,
                  width: context.rs(20, min: 18, max: 22),
                  height: context.rs(20, min: 18, max: 22),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.rs(6, min: 6, max: 8)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AppImage(
                  source: item.imagePath,
                  width: double.infinity,
                  height: imageHeight ?? context.rs(160, min: 150, max: 172),
                  fit: BoxFit.cover,
                ),
                if (item.showPlayIcon)
                  Container(
                    width: context.rs(34, min: 32, max: 38),
                    height: context.rs(34, min: 32, max: 38),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.88),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: context.rs(22, min: 20, max: 24),
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.rs(10, min: 10, max: 12),
              contentTopPadding ?? context.rs(8, min: 8, max: 10),
              context.rs(10, min: 10, max: 12),
              contentBottomPadding ?? context.rs(10, min: 10, max: 12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.caption,
                  style: TextStyle(
                    fontSize: context.rs(11.5, min: 11, max: 12.5),
                    fontWeight: FontWeight.w400,
                    color: primaryTextColor,
                  ),
                ),
                context.rs(4, min: 4, max: 5).vSpace,
                Text(
                  item.tags,
                  style: TextStyle(
                    fontSize: context.rs(10.5, min: 10, max: 11),
                    fontWeight: FontWeight.w400,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
