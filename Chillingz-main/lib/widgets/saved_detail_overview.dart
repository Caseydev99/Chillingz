import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/utils/extensions.dart';
import '../core/widgets/app_image.dart';
import '../features/home/models/saved_detail_item.dart';

class SavedDetailOverview extends StatelessWidget {
  const SavedDetailOverview({
    super.key,
    required this.item,
    required this.isLiked,
    required this.isLikePending,
    required this.onLikeTap,
  });

  final SavedDetailItem item;
  final bool isLiked;
  final bool isLikePending;
  final VoidCallback onLikeTap;

  @override
  Widget build(BuildContext context) {
    final title = item.venueName.isNotEmpty ? item.venueName : item.title;
    final subtitle = item.venueName.isNotEmpty && item.title != item.venueName
        ? item.title
        : '';
    final detailChips = <_DetailChipData>[
      if (item.subcategory.isNotEmpty)
        _DetailChipData(Icons.local_offer_outlined, item.subcategory),
      if (item.parentCategory.isNotEmpty)
        _DetailChipData(Icons.grid_view_rounded, item.parentCategory),
      if (item.parentCategory.isEmpty && item.category.isNotEmpty)
        _DetailChipData(Icons.grid_view_rounded, item.category),
      if (item.priceLabel.isNotEmpty)
        _DetailChipData(Icons.payments_outlined, item.priceLabel),
      if (item.rating.isNotEmpty)
        _DetailChipData(AppIcons.star, item.rating, accent: true),
      if (item.distance.isNotEmpty)
        _DetailChipData(AppIcons.location, item.distance),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(context.rs(22, min: 20, max: 24)),
          child: AspectRatio(
            aspectRatio: 1.2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(source: item.imagePath, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.72),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: context.rs(16, min: 14, max: 18),
                  right: context.rs(16, min: 14, max: 18),
                  bottom: context.rs(16, min: 14, max: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: context.rs(22, min: 20, max: 24),
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              context.rs(6, min: 5, max: 7).vSpace,
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.white.withOpacity(0.86),
                                  fontSize: context.rs(13, min: 12, max: 14),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      context.rs(12, min: 10, max: 14).hSpace,
                      _FavoriteCircleButton(
                        isLiked: isLiked,
                        isPending: isLikePending,
                        onTap: onLikeTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (detailChips.isNotEmpty) ...[
          context.rs(16, min: 14, max: 18).vSpace,
          Wrap(
            spacing: context.rs(8, min: 7, max: 10),
            runSpacing: context.rs(8, min: 7, max: 10),
            children: detailChips.map((chip) {
              return _DetailChip(data: chip);
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _FavoriteCircleButton extends StatelessWidget {
  const _FavoriteCircleButton({
    required this.isLiked,
    required this.isPending,
    required this.onTap,
  });

  final bool isLiked;
  final bool isPending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPending ? null : onTap,
      child: Container(
        width: context.rs(44, min: 40, max: 48),
        height: context.rs(44, min: 40, max: 48),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.92),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedScale(
            scale: isPending ? 0.92 : 1,
            duration: const Duration(milliseconds: 120),
            child: Icon(
              isLiked ? AppIcons.favorite : AppIcons.favoriteBorder,
              color: const Color(0xFFE54949),
              size: context.rs(22, min: 20, max: 24),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.data});

  final _DetailChipData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(11, min: 10, max: 12),
        vertical: context.rs(7, min: 6, max: 8),
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data.icon,
            size: context.rs(15, min: 14, max: 16),
            color: data.accent ? const Color(0xFFFFC62A) : AppColors.primary,
          ),
          context.rs(6, min: 5, max: 7).hSpace,
          Text(
            data.label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: context.rs(12, min: 11.5, max: 13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChipData {
  const _DetailChipData(this.icon, this.label, {this.accent = false});

  final IconData icon;
  final String label;
  final bool accent;
}
