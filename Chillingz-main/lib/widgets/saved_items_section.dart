import 'package:flutter/material.dart';

import '../core/utils/extensions.dart';
import '../features/home/models/saved_detail_item.dart';
import 'saved_detail_card.dart';
import 'saved_section_title.dart';

class SavedItemsSection extends StatelessWidget {
  const SavedItemsSection({
    super.key,
    required this.title,
    required this.items,
    required this.isLiked,
    required this.onToggle,
    this.isPending,
    this.onItemTap,
    this.trailingLabel,
    this.onTrailingTap,
  });

  final String title;
  final List<SavedDetailItem> items;
  final bool Function(String id) isLiked;
  final ValueChanged<String> onToggle;
  final bool Function(String id)? isPending;
  final ValueChanged<SavedDetailItem>? onItemTap;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SavedSectionTitle(
          title: title,
          trailingLabel: trailingLabel,
          onTrailingTap: onTrailingTap,
        ),
        context.rs(9, min: 8, max: 10).vSpace,
        ...List.generate(items.length, (index) {
          final item = items[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == items.length - 1
                  ? 0
                  : context.rs(8, min: 8, max: 10),
            ),
            child: SavedDetailCard(
              item: item,
              isLiked: isLiked(item.id),
              isLikePending: isPending?.call(item.id) ?? false,
              onLikeTap: () => onToggle(item.id),
              onTap: onItemTap == null ? null : () => onItemTap!(item),
            ),
          );
        }),
      ],
    );
  }
}
