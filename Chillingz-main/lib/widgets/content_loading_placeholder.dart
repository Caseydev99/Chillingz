import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';

class ContentLoadingPlaceholder extends StatelessWidget {
  const ContentLoadingPlaceholder({
    super.key,
    this.itemCount = 3,
    this.grid = false,
    this.topPadding,
  });

  final int itemCount;
  final bool grid;
  final double? topPadding;

  @override
  Widget build(BuildContext context) {
    final paddingTop = topPadding ?? context.rs(8, min: 6, max: 10);
    if (grid) {
      return Padding(
        padding: EdgeInsets.only(top: paddingTop),
        child: GridView.builder(
          itemCount: itemCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.16,
          ),
          itemBuilder: (context, index) {
            return _PlaceholderBlock(
              borderRadius: context.rs(10, min: 10, max: 12),
            );
          },
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: paddingTop),
      child: Column(
        children: List.generate(itemCount, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: context.rs(10, min: 10, max: 12)),
            child: Row(
              children: [
                _PlaceholderBlock(
                  width: context.rs(68, min: 62, max: 76),
                  height: context.rs(68, min: 62, max: 76),
                  borderRadius: context.rs(10, min: 10, max: 12),
                ),
                context.rs(12, min: 10, max: 14).hSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PlaceholderBlock(
                        height: context.rs(15, min: 14, max: 16),
                        width: double.infinity,
                        borderRadius: 999,
                      ),
                      context.rs(8, min: 7, max: 9).vSpace,
                      _PlaceholderBlock(
                        height: context.rs(12, min: 11, max: 13),
                        width: context.rs(150, min: 130, max: 180),
                        borderRadius: 999,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _PlaceholderBlock extends StatelessWidget {
  const _PlaceholderBlock({
    this.width,
    this.height,
    required this.borderRadius,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}
