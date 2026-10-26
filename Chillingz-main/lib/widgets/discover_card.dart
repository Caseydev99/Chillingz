import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';
import '../core/widgets/app_image.dart';
import '../features/home/models/home_discovery_item.dart';

class DiscoverCard extends StatelessWidget {
  const DiscoverCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final HomeDiscoveryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = context.rs(12, min: 11, max: 14);

    return Material(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: item.isNature ? 1.72 : 1.86,
              child: AppImage(
                source: item.imagePath,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                context.rs(14, min: 12, max: 16),
                context.rs(11, min: 10, max: 13),
                context.rs(14, min: 12, max: 16),
                context.rs(13, min: 12, max: 15),
              ),
              color: const Color(0xFF4A1574),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.rs(13.5, min: 13, max: 14.5),
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  if (item.tag.isNotEmpty) ...[
                    context.rs(10, min: 8, max: 12).hSpace,
                    Flexible(
                      flex: 0,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: context.rs(96, min: 82, max: 118),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: context.rs(8, min: 7, max: 9),
                          vertical: context.rs(4, min: 3, max: 5),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.tag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.rs(10.5, min: 10, max: 11),
                            fontWeight: FontWeight.w500,
                            color: AppColors.white,
                          ),
                        ),
                      ),
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
