import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/utils/extensions.dart';
import '../core/widgets/app_image.dart';
import '../features/home/models/music_event_item.dart';

class MusicEventCard extends StatelessWidget {
  const MusicEventCard({
    super.key,
    required this.item,
    required this.isLiked,
    required this.onLikeTap,
    this.isLikePending = false,
    this.onTap,
    this.isCompact = false,
    this.featuredStyle = false,
    this.eventStyle = false,
    this.backgroundColor,
  });

  final MusicEventItem item;
  final bool isLiked;
  final VoidCallback onLikeTap;
  final bool isLikePending;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool featuredStyle;
  final bool eventStyle;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (eventStyle) {
      return _EventMusicCard(
        item: item,
        isLiked: isLiked,
        isLikePending: isLikePending,
        onLikeTap: onLikeTap,
        onTap: onTap,
        expandToWidth: featuredStyle,
      );
    }

    if (isCompact || featuredStyle) {
      return _CompactMusicEventCard(
        item: item,
        isLiked: isLiked,
        isLikePending: isLikePending,
        onLikeTap: onLikeTap,
        onTap: onTap,
        expandToWidth: featuredStyle,
      );
    }

    final radius = context.rs(12, min: 12, max: 14);
    final imageHeight = context.rs(138, min: 130, max: 146);
    final horizontalPadding = context.rs(10, min: 10, max: 12);
    final topPadding = context.rs(7, min: 7, max: 9);
    final bottomPadding = context.rs(9, min: 8, max: 10);
    final titleSize = context.rs(14, min: 13.5, max: 15);
    final metaSize = context.rs(10.5, min: 10, max: 11);
    final ratingIconSize = context.rs(12, min: 11, max: 13);
    final ratingTextSize = context.rs(10.5, min: 10, max: 11);
    final displayLocation = item.venueName.isNotEmpty
        ? item.venueName
        : item.location;
    final metaLine = [
      item.headliner,
      item.subcategory,
      item.timeLabel,
    ].where((value) => value.trim().isNotEmpty).join(' / ');
    final hasRating = item.rating.trim().isNotEmpty;
    final hasPrice = item.priceLabel.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.musicEventCardBackground,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageSection(
              imagePath: item.imagePath,
              badgeText: item.badgeText,
              isLiked: isLiked,
              isLikePending: isLikePending,
              onLikeTap: onLikeTap,
              height: imageHeight,
              radius: radius,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (hasRating) ...[
                        Icon(
                          AppIcons.star,
                          size: ratingIconSize,
                          color: const Color(0xFFFFC62A),
                        ),
                        (isCompact
                                ? context.rs(2, min: 2, max: 3)
                                : context.rs(3, min: 2, max: 4))
                            .hSpace,
                        Text(
                          item.rating,
                          style: TextStyle(
                            fontSize: ratingTextSize,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (metaLine.isNotEmpty) ...[
                    context.rs(2, min: 2, max: 3).vSpace,
                    Text(
                      metaLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: metaSize,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  (isCompact
                          ? context.rs(1.5, min: 1, max: 2)
                          : context.rs(2, min: 2, max: 3))
                      .vSpace,
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: metaSize,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6FA0A8),
                          ),
                        ),
                      ),
                      if (hasPrice)
                        Text(
                          item.priceLabel,
                          style: TextStyle(
                            fontSize: metaSize,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventMusicCard extends StatelessWidget {
  const _EventMusicCard({
    required this.item,
    required this.isLiked,
    required this.isLikePending,
    required this.onLikeTap,
    this.onTap,
    this.expandToWidth = false,
  });

  final MusicEventItem item;
  final bool isLiked;
  final bool isLikePending;
  final VoidCallback onLikeTap;
  final VoidCallback? onTap;
  final bool expandToWidth;

  @override
  Widget build(BuildContext context) {
    final radius = context.rs(14, min: 13, max: 16);
    final displayLocation = item.venueName.isNotEmpty
        ? item.venueName
        : item.location;
    final metaLine = [
      item.headliner,
      item.subcategory,
      item.timeLabel,
    ].where((value) => value.trim().isNotEmpty).join(' / ');
    final hasRating = item.rating.trim().isNotEmpty;
    final hasPrice = item.priceLabel.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          context.rs(6, min: 6, max: 7),
          context.rs(6, min: 6, max: 7),
          context.rs(6, min: 6, max: 7),
          context.rs(8, min: 8, max: 10),
        ),
        decoration: BoxDecoration(
          color: AppColors.eventCardBackground,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: const Color(0xFF9A4E8F), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                context.rs(11, min: 10, max: 12),
              ),
              child: SizedBox(
                height: expandToWidth
                    ? context.rs(120, min: 114, max: 128)
                    : context.rs(118, min: 110, max: 122),
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(source: item.imagePath, fit: BoxFit.cover),
                    if (item.badgeText.trim().isNotEmpty)
                      Positioned(
                        top: context.rs(7, min: 7, max: 8),
                        left: context.rs(7, min: 7, max: 8),
                        child: _Badge(badgeText: item.badgeText),
                      ),
                    Positioned(
                      top: context.rs(8, min: 8, max: 10),
                      right: context.rs(8, min: 8, max: 10),
                      child: _FavoriteButton(
                        isLiked: isLiked,
                        isPending: isLikePending,
                        onTap: onLikeTap,
                        size: context.rs(18, min: 17, max: 20),
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            context.rs(7, min: 6, max: 8).vSpace,
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.rs(13.5, min: 13, max: 14.5),
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ),
                if (hasRating) ...[
                  Icon(
                    AppIcons.star,
                    size: context.rs(13, min: 12, max: 14),
                    color: const Color(0xFFFFC62A),
                  ),
                  context.rs(2, min: 2, max: 3).hSpace,
                  Text(
                    item.rating,
                    style: TextStyle(
                      fontSize: context.rs(10.5, min: 10, max: 11),
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ],
            ),
            if (metaLine.isNotEmpty) ...[
              context.rs(2, min: 2, max: 3).vSpace,
              Text(
                metaLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.rs(9.5, min: 9, max: 10),
                  fontWeight: FontWeight.w400,
                  color: AppColors.white.withOpacity(0.82),
                ),
              ),
            ],
            context.rs(2, min: 2, max: 3).vSpace,
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.rs(9.5, min: 9, max: 10),
                      fontWeight: FontWeight.w400,
                      color: AppColors.white.withOpacity(0.82),
                    ),
                  ),
                ),
                if (hasPrice)
                  Text(
                    item.priceLabel,
                    style: TextStyle(
                      fontSize: context.rs(9.5, min: 9, max: 10),
                      fontWeight: FontWeight.w400,
                      color: AppColors.white.withOpacity(0.82),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMusicEventCard extends StatelessWidget {
  const _CompactMusicEventCard({
    required this.item,
    required this.isLiked,
    required this.isLikePending,
    required this.onLikeTap,
    this.onTap,
    this.expandToWidth = false,
  });

  final MusicEventItem item;
  final bool isLiked;
  final bool isLikePending;
  final VoidCallback onLikeTap;
  final VoidCallback? onTap;
  final bool expandToWidth;

  @override
  Widget build(BuildContext context) {
    final cardWidth = expandToWidth
        ? double.infinity
        : context.rs(272, min: 250, max: 282);
    final radius = context.rs(16, min: 15, max: 17);
    final imageRadius = context.rs(14, min: 13, max: 15);
    final displayLocation = item.venueName.isNotEmpty
        ? item.venueName
        : item.location;
    final metaLine = [
      item.headliner,
      item.subcategory,
      item.timeLabel,
    ].where((value) => value.trim().isNotEmpty).join(' / ');
    final hasRating = item.rating.trim().isNotEmpty;
    final hasPrice = item.priceLabel.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        padding: EdgeInsets.fromLTRB(
          context.rs(7, min: 6, max: 8),
          context.rs(7, min: 6, max: 8),
          context.rs(7, min: 6, max: 8),
          context.rs(10, min: 9, max: 11),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2D4E83),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: const Color(0xFF42D9FF), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(imageRadius),
              child: SizedBox(
                height: expandToWidth
                    ? context.rs(126, min: 120, max: 132)
                    : context.rs(118, min: 112, max: 124),
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(source: item.imagePath, fit: BoxFit.cover),
                    if (item.badgeText.trim().isNotEmpty)
                      Positioned(
                        top: context.rs(8, min: 8, max: 10),
                        left: context.rs(8, min: 8, max: 10),
                        child: _Badge(badgeText: item.badgeText),
                      ),
                    Positioned(
                      top: context.rs(8, min: 8, max: 10),
                      right: context.rs(8, min: 8, max: 10),
                      child: _FavoriteButton(
                        isLiked: isLiked,
                        isPending: isLikePending,
                        onTap: onLikeTap,
                        size: context.rs(22, min: 20, max: 24),
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            context.rs(10, min: 9, max: 11).vSpace,
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.rs(14, min: 13.5, max: 15),
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ),
                if (hasRating) ...[
                  Icon(
                    AppIcons.star,
                    size: context.rs(14, min: 13, max: 15),
                    color: const Color(0xFFFFC62A),
                  ),
                  context.rs(3, min: 3, max: 4).hSpace,
                  Text(
                    item.rating,
                    style: TextStyle(
                      fontSize: context.rs(12, min: 11.5, max: 12.5),
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ],
            ),
            if (metaLine.isNotEmpty) ...[
              context.rs(3, min: 2, max: 4).vSpace,
              Text(
                metaLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.rs(10.5, min: 10, max: 11),
                  fontWeight: FontWeight.w400,
                  color: AppColors.white.withOpacity(0.88),
                ),
              ),
            ],
            context.rs(3, min: 2, max: 4).vSpace,
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.rs(10.5, min: 10, max: 11),
                      fontWeight: FontWeight.w400,
                      color: AppColors.white.withOpacity(0.88),
                    ),
                  ),
                ),
                if (hasPrice)
                  Text(
                    item.priceLabel,
                    style: TextStyle(
                      fontSize: context.rs(10.5, min: 10, max: 11),
                      fontWeight: FontWeight.w400,
                      color: AppColors.white.withOpacity(0.88),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.imagePath,
    required this.badgeText,
    required this.isLiked,
    required this.isLikePending,
    required this.onLikeTap,
    required this.height,
    required this.radius,
  });

  final String imagePath;
  final String badgeText;
  final bool isLiked;
  final bool isLikePending;
  final VoidCallback onLikeTap;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppImage(source: imagePath, fit: BoxFit.cover),
            if (badgeText.trim().isNotEmpty)
              Positioned(
                top: context.rs(8, min: 8, max: 10),
                left: context.rs(8, min: 8, max: 10),
                child: _Badge(badgeText: badgeText),
              ),
            Positioned(
              top: context.rs(10, min: 9, max: 11),
              right: context.rs(10, min: 9, max: 11),
              child: _FavoriteButton(
                isLiked: isLiked,
                isPending: isLikePending,
                onTap: onLikeTap,
                size: context.rs(18, min: 17, max: 19),
                color: AppColors.white,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.badgeText});

  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.rs(34, min: 32, max: 36),
      padding: EdgeInsets.symmetric(vertical: context.rs(4, min: 4, max: 5)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(context.rs(8, min: 8, max: 9)),
      ),
      child: Text(
        badgeText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: context.rs(7.5, min: 7, max: 8),
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          height: 1.15,
        ),
      ),
    );
  }
}
