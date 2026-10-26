import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/utils/extensions.dart';
import '../core/widgets/app_image.dart';
import '../features/home/models/music_event_item.dart';

class MusicEventOverview extends StatelessWidget {
  const MusicEventOverview({
    super.key,
    required this.item,
    required this.isLiked,
    required this.isLikePending,
    required this.onLikeTap,
  });

  final MusicEventItem item;
  final bool isLiked;
  final bool isLikePending;
  final VoidCallback onLikeTap;

  @override
  Widget build(BuildContext context) {
    final location = item.venueName.isNotEmpty ? item.venueName : item.location;
    final chips = <_MusicDetailChipData>[
      if (item.headliner.isNotEmpty)
        _MusicDetailChipData(Icons.mic_none_rounded, item.headliner),
      if (item.subcategory.isNotEmpty)
        _MusicDetailChipData(Icons.local_offer_outlined, item.subcategory),
      if (item.timeLabel.isNotEmpty)
        _MusicDetailChipData(Icons.schedule_rounded, item.timeLabel),
      if (location.isNotEmpty)
        _MusicDetailChipData(AppIcons.location, location),
      if (item.priceLabel.isNotEmpty)
        _MusicDetailChipData(Icons.payments_outlined, item.priceLabel),
      if (item.rating.isNotEmpty)
        _MusicDetailChipData(AppIcons.star, item.rating, accent: true),
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
                if (item.badgeText.trim().isNotEmpty)
                  Positioned(
                    top: context.rs(14, min: 12, max: 16),
                    left: context.rs(14, min: 12, max: 16),
                    child: _DateBadge(label: item.badgeText),
                  ),
                Positioned(
                  left: context.rs(16, min: 14, max: 18),
                  right: context.rs(16, min: 14, max: 18),
                  bottom: context.rs(16, min: 14, max: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: context.rs(22, min: 20, max: 24),
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
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
        if (chips.isNotEmpty) ...[
          context.rs(16, min: 14, max: 18).vSpace,
          Wrap(
            spacing: context.rs(8, min: 7, max: 10),
            runSpacing: context.rs(8, min: 7, max: 10),
            children: chips
                .map((chip) => _MusicDetailChip(data: chip))
                .toList(),
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

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.rs(42, min: 38, max: 46),
      padding: EdgeInsets.symmetric(vertical: context.rs(6, min: 5, max: 7)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(context.rs(10, min: 9, max: 11)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: context.rs(9, min: 8.5, max: 10),
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}

class _MusicDetailChip extends StatelessWidget {
  const _MusicDetailChip({required this.data});

  final _MusicDetailChipData data;

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

class _MusicDetailChipData {
  const _MusicDetailChipData(this.icon, this.label, {this.accent = false});

  final IconData icon;
  final String label;
  final bool accent;
}
