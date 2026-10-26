import 'package:flutter/material.dart';

import '../features/home/models/home_discovery_item.dart';
import 'discover_card.dart';

class DiscoverItemsList extends StatefulWidget {
  const DiscoverItemsList({
    super.key,
    required this.items,
    this.onItemTap,
    this.refreshToken = 0,
  });

  final List<HomeDiscoveryItem> items;
  final ValueChanged<HomeDiscoveryItem>? onItemTap;

  /// Bumped by the caller (e.g. a refresh button) to request a fresh pick of
  /// visible recommendations from [items], discarding any previously
  /// dismissed/active selection.
  final int refreshToken;

  @override
  State<DiscoverItemsList> createState() => _DiscoverItemsListState();
}

class _DiscoverItemsListState extends State<DiscoverItemsList> {
  static const int _visibleRecommendationLimit = 6;
  final List<String> _activeItemIds = <String>[];
  final Set<String> _dismissedItemIds = <String>{};
  int _lastRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _lastRefreshToken = widget.refreshToken;
    _syncActiveItems();
  }

  @override
  void didUpdateWidget(covariant DiscoverItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != _lastRefreshToken) {
      _lastRefreshToken = widget.refreshToken;
      _activeItemIds.clear();
      _dismissedItemIds.clear();
    }
    _syncActiveItems();
  }

  void _syncActiveItems() {
    final availableIds = widget.items.map((item) => item.id).toSet();
    _dismissedItemIds.removeWhere((id) => !availableIds.contains(id));
    _activeItemIds.removeWhere(
      (id) => !availableIds.contains(id) || _dismissedItemIds.contains(id),
    );

    for (final item in widget.items) {
      if (_activeItemIds.length >= _visibleRecommendationLimit) {
        break;
      }
      if (!_dismissedItemIds.contains(item.id) &&
          !_activeItemIds.contains(item.id)) {
        _activeItemIds.add(item.id);
      }
    }
  }

  void _replaceRecommendation(int index, HomeDiscoveryItem dismissedItem) {
    setState(() {
      _dismissedItemIds.add(dismissedItem.id);
      final activeIds = _activeItemIds.toSet()..remove(dismissedItem.id);
      HomeDiscoveryItem? replacement;
      final dismissedTagKey = _normalizedTagKey(dismissedItem.tag);

      // Preserve the 2/2/2 mix by replacing a dismissed recommendation with
      // another item for the same selected interest whenever one exists.
      for (final item in widget.items) {
        if (!_dismissedItemIds.contains(item.id) &&
            !activeIds.contains(item.id) &&
            _normalizedTagKey(item.tag) == dismissedTagKey) {
          replacement = item;
          break;
        }
      }
      replacement ??= _firstAvailableReplacement(activeIds);

      if (replacement == null) {
        _activeItemIds.removeAt(index);
      } else {
        _activeItemIds[index] = replacement.id;
      }
    });
  }

  HomeDiscoveryItem? _firstAvailableReplacement(Set<String> activeIds) {
    for (final item in widget.items) {
      if (!_dismissedItemIds.contains(item.id) &&
          !activeIds.contains(item.id)) {
        return item;
      }
    }
    return null;
  }

  static String _normalizedTagKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  @override
  Widget build(BuildContext context) {
    final itemsById = <String, HomeDiscoveryItem>{
      for (final item in widget.items) item.id: item,
    };
    final activeItems = _activeItemIds
        .map((id) => itemsById[id])
        .whereType<HomeDiscoveryItem>()
        .toList();

    if (activeItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No more matching recommendations right now',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(activeItems.length, (index) {
        final item = activeItems[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == activeItems.length - 1 ? 0 : 16,
          ),
          child: Dismissible(
            key: ValueKey<String>(item.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _replaceRecommendation(index, item),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 30,
              ),
            ),
            child: DiscoverCard(
              item: item,
              onTap: widget.onItemTap == null
                  ? null
                  : () => widget.onItemTap!(item),
            ),
          ),
        );
      }),
    );
  }
}
