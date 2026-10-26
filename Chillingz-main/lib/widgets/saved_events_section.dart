import 'package:flutter/material.dart';

import '../core/utils/extensions.dart';
import '../features/home/models/saved_event_item.dart';
import 'saved_event_card.dart';
import 'saved_section_title.dart';

class SavedEventsSection extends StatelessWidget {
  const SavedEventsSection({
    super.key,
    required this.title,
    required this.items,
    required this.likedIds,
    required this.onToggle,
    this.isPending,
    this.onItemTap,
  });

  final String title;
  final List<SavedEventItem> items;
  final Set<String> likedIds;
  final ValueChanged<String> onToggle;
  final bool Function(String id)? isPending;
  final ValueChanged<SavedEventItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final cardHeight = context.rs(184, min: 176, max: 192);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SavedSectionTitle(title: title),
        context.rs(10, min: 10, max: 12).vSpace,
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            separatorBuilder: (context, index) =>
                SizedBox(width: context.rs(10, min: 8, max: 12)),
            itemBuilder: (context, index) {
              final item = items[index];
              return SavedEventCard(
                item: item,
                isLiked: likedIds.contains(item.id),
                isLikePending: isPending?.call(item.id) ?? false,
                onLikeTap: () => onToggle(item.id),
                onTap: onItemTap == null ? null : () => onItemTap!(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
