import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';
import '../core/widgets/app_image.dart';
import '../features/home/models/home_category_item.dart';

class HomeCategoryTile extends StatelessWidget {
  const HomeCategoryTile({
    super.key,
    required this.item,
    this.onTap,
  });

  final HomeCategoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppImage(
              source: item.imagePath,
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    item.darkOverlay
                        ? Colors.black.withOpacity(0.08)
                        : Colors.transparent,
                    Colors.black.withOpacity(0.68),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    item.icon,
                    size: 15,
                    color: AppColors.isLightMode
                        ? AppColors.primary
                        : AppColors.white,
                  ),
                  6.hSpace,
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                        height: 1.2,
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
