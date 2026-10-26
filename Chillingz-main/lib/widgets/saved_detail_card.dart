import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/utils/extensions.dart';
import '../core/widgets/app_image.dart';
import '../features/home/models/saved_detail_item.dart';
import '../features/home/providers/home_provider.dart';

class SavedDetailCard extends StatelessWidget {
  const SavedDetailCard({
    super.key,
    required this.item,
    required this.isLiked,
    required this.onLikeTap,
    this.isLikePending = false,
    this.onTap,
  });

  final SavedDetailItem item;
  final bool isLiked;
  final VoidCallback onLikeTap;
  final bool isLikePending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardRadius = context.rs(15, min: 14, max: 17);
    final imageHeight = context.rs(132, min: 124, max: 142);
    final titleFontSize = context.rs(14.2, min: 13.6, max: 15);
    final metaFontSize = context.rs(11.2, min: 10.8, max: 12);
    final displayTitle = item.venueName.isNotEmpty
        ? item.venueName
        : item.title;
    final bottomLabel =
        item.venueName.isNotEmpty && item.title != item.venueName
        ? item.title
        : item.parentCategory.isNotEmpty
        ? item.parentCategory
        : item.category;
    final subtitle = [
      item.subcategory,
      if (item.subcategory.isEmpty) item.parentCategory,
      if (item.subcategory.isEmpty && item.parentCategory.isEmpty)
        item.category,
    ].where((value) => value.trim().isNotEmpty).join(' / ');
    final distanceLabel = context.select<HomeProvider, String>(
      (provider) => provider.distanceLabelFor(item),
    );
    final hasDistance = distanceLabel.isNotEmpty;
    final hasRating = item.rating.trim().isNotEmpty;
    final hasPrice = item.priceLabel.trim().isNotEmpty;
    final borderColor =
        item.backgroundColor == AppColors.activitiesCardBackground
        ? const Color(0xFFFF55D3)
        : item.backgroundColor == AppColors.foodCardBackground
        ? const Color(0xFFFF8A8A)
        : item.backgroundColor == AppColors.healthCardBackground
        ? const Color(0xFF00FF66)
        : item.backgroundColor == AppColors.networkingCardBackground
        ? const Color(0xFF4A63FF)
        : AppColors.border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: item.backgroundColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(source: item.imagePath, fit: BoxFit.cover),
                  Positioned(
                    top: context.rs(10, min: 9, max: 11),
                    right: context.rs(10, min: 9, max: 11),
                    child: _FavoriteButton(
                      isLiked: isLiked,
                      isPending: isLikePending,
                      onTap: onLikeTap,
                      size: context.rs(23, min: 21, max: 25),
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(context.rs(11, min: 10, max: 13)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: context.rs(3, min: 2, max: 4),
                      ),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: metaFontSize,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  context.rs(5, min: 5, max: 6).vSpace,
                  if (bottomLabel.isNotEmpty || hasPrice)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bottomLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: metaFontSize,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6FA0A8),
                            ),
                          ),
                        ),
                        if (hasPrice)
                          Text(
                            item.priceLabel,
                            style: TextStyle(
                              fontSize: metaFontSize,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textPrimary,
                            ),
                          ),
                      ],
                    ),
                  if (hasDistance || hasRating) ...[
                    context.rs(6, min: 5, max: 7).vSpace,
                    Row(
                      children: [
                        if (hasDistance) ...[
                          Icon(
                            AppIcons.location,
                            size: context.rs(14, min: 13, max: 15),
                            color: AppColors.textSecondary,
                          ),
                          context.rs(4, min: 4, max: 5).hSpace,
                          Text(
                            distanceLabel,
                            style: TextStyle(
                              fontSize: metaFontSize,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (hasDistance && hasRating)
                          context.rs(12, min: 10, max: 14).hSpace,
                        if (hasRating) ...[
                          Icon(
                            AppIcons.star,
                            size: context.rs(14, min: 13, max: 15),
                            color: const Color(0xFFFFC62A),
                          ),
                          context.rs(4, min: 4, max: 5).hSpace,
                          Text(
                            item.rating,
                            style: TextStyle(
                              fontSize: metaFontSize,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isLiked,
    required this.isPending,
    required this.onTap,
    required this.size,
    required this.color,
  });

  final bool isLiked;
  final bool isPending;
  final VoidCallback onTap;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPending ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isPending ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        child: Icon(
          isLiked ? AppIcons.favorite : AppIcons.favoriteBorder,
          size: size,
          color: color,
        ),
      ),
    );
  }
}
