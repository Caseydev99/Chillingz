import 'package:flutter/material.dart';

import '../features/home/models/home_category_item.dart';
import 'home_category_tile.dart';

class HomeCategoriesGrid extends StatelessWidget {
  const HomeCategoriesGrid({
    super.key,
    required this.items,
    this.onItemTap,
  });

  final List<HomeCategoryItem> items;
  final ValueChanged<HomeCategoryItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return HomeCategoryTile(
          item: item,
          onTap: onItemTap == null ? null : () => onItemTap!(item),
        );
      },
    );
  }
}
