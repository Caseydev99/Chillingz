import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/utils/extensions.dart';
import '../core/widgets/app_image.dart';
import '../features/home/models/music_genre_item.dart';

class MusicGenreCard extends StatelessWidget {
  const MusicGenreCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final MusicGenreItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.rs(10, min: 10, max: 12)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppImage(
              source: item.imagePath,
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.musicGenreBaseOverlay,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.musicGenreTopOverlay,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.musicGenreBottomOverlay,
              ),
            ),
            Positioned(
              left: context.rs(10, min: 9, max: 11),
              right: context.rs(10, min: 9, max: 11),
              bottom: context.rs(10, min: 9, max: 11),
              child: Row(
                children: [
                  Icon(
                    AppIcons.music,
                    size: context.rs(14, min: 13, max: 15),
                    color: AppColors.white,
                  ),
                  context.rs(6, min: 5, max: 7).hSpace,
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.rs(12, min: 11.5, max: 13),
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
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
