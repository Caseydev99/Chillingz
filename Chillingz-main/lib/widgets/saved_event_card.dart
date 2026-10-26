import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/utils/extensions.dart';
import '../core/widgets/app_image.dart';
import '../features/home/models/saved_event_item.dart';

class SavedEventCard extends StatelessWidget {
  const SavedEventCard({
    super.key,
    required this.item,
    required this.isLiked,
    required this.onLikeTap,
    this.isLikePending = false,
    this.onTap,
  });

  final SavedEventItem item;
  final bool isLiked;
  final VoidCallback onLikeTap;
  final bool isLikePending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardWidth = context.rs(242, min: 228, max: 250);
    final cardTextSecondary = AppColors.isLightMode
        ? AppColors.textSecondary
        : AppColors.white.withOpacity(0.86);

    return SizedBox(
      width: cardWidth,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = constraints.maxHeight * 0.62;

          return GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                context.rs(6, min: 5, max: 7),
                context.rs(6, min: 5, max: 7),
                context.rs(6, min: 5, max: 7),
                context.rs(9, min: 8, max: 10),
              ),
              decoration: BoxDecoration(
                color: const Color(0x4D434261),
                border: Border.all(color: const Color(0xFF2EE6F5), width: 0.5),
                borderRadius: BorderRadius.circular(
                  context.rs(15, min: 14, max: 17),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        context.rs(12, min: 12, max: 14),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppImage(source: item.imagePath, fit: BoxFit.cover),
                          Positioned(
                            top: context.rs(7, min: 7, max: 8),
                            left: context.rs(7, min: 7, max: 8),
                            child: Container(
                              width: context.rs(32, min: 30, max: 36),
                              padding: EdgeInsets.symmetric(
                                vertical: context.rs(4, min: 4, max: 5),
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(
                                  context.rs(8, min: 8, max: 9),
                                ),
                              ),
                              child: Text(
                                item.badgeText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: context.rs(7.4, min: 7, max: 8),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: context.rs(8, min: 8, max: 9),
                            right: context.rs(8, min: 8, max: 9),
                            child: GestureDetector(
                              onTap: isLikePending ? null : onLikeTap,
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedScale(
                                scale: isLikePending ? 0.92 : 1,
                                duration: const Duration(milliseconds: 120),
                                child: Icon(
                                  isLiked
                                      ? AppIcons.favorite
                                      : AppIcons.heartOutline,
                                  size: context.rs(18, min: 17, max: 19),
                                  color: const Color(0xFFE24B4B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  context.rs(8, min: 7, max: 8).vSpace,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.rs(14, min: 13.4, max: 14.6),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        AppIcons.star,
                        size: context.rs(12.5, min: 12, max: 13),
                        color: const Color(0xFFFFC62A),
                      ),
                      SizedBox(width: context.rs(3, min: 3, max: 4)),
                      Text(
                        '4.7',
                        style: TextStyle(
                          fontSize: context.rs(10.2, min: 9.8, max: 10.8),
                          fontWeight: FontWeight.w400,
                          color: cardTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  context.rs(2, min: 2, max: 3).vSpace,
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.rs(10.1, min: 9.8, max: 10.6),
                            fontWeight: FontWeight.w400,
                            color: AppColors.isLightMode
                                ? AppColors.textSecondary
                                : AppColors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      SizedBox(width: context.rs(8, min: 6, max: 8)),
                      Text(
                        item.priceLabel,
                        style: TextStyle(
                          fontSize: context.rs(9.8, min: 9.4, max: 10.2),
                          fontWeight: FontWeight.w400,
                          color: cardTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
