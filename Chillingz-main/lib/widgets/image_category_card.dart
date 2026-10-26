import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';
import '../core/widgets/app_image.dart';

class ImageCategoryCard extends StatelessWidget {
  const ImageCategoryCard({
    super.key,
    required this.title,
    required this.imagePath,
    this.onTap,
  });

  final String title;
  final String imagePath;
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
              source: imagePath,
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.12),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              left: context.rs(10, min: 9, max: 11),
              right: context.rs(10, min: 9, max: 11),
              bottom: context.rs(10, min: 9, max: 11),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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
    );
  }
}
