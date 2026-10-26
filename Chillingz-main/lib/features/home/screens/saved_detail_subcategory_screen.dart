import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_screen_header.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/saved_detail_card.dart';
import '../models/food_cuisine_item.dart';
import '../models/saved_detail_item.dart';
import '../providers/home_provider.dart';

enum SavedDetailSubcategoryKind { activities, health, networking }

class SavedDetailSubcategoryArgs {
  const SavedDetailSubcategoryArgs({required this.item, required this.kind});

  final FoodCuisineItem item;
  final SavedDetailSubcategoryKind kind;
}

class SavedDetailSubcategoryScreen extends StatelessWidget {
  const SavedDetailSubcategoryScreen({super.key, required this.args});

  final SavedDetailSubcategoryArgs args;

  List<SavedDetailItem> _items(HomeProvider provider) {
    switch (args.kind) {
      case SavedDetailSubcategoryKind.activities:
        return provider.activitySubcategoryItems(args.item);
      case SavedDetailSubcategoryKind.health:
        return provider.healthSubcategoryItems(args.item);
      case SavedDetailSubcategoryKind.networking:
        return provider.networkingSubcategoryItems(args.item);
    }
  }

  IconData get _emptyIcon {
    switch (args.kind) {
      case SavedDetailSubcategoryKind.activities:
        return Icons.explore_outlined;
      case SavedDetailSubcategoryKind.health:
        return Icons.spa_outlined;
      case SavedDetailSubcategoryKind.networking:
        return Icons.groups_outlined;
    }
  }

  String get _detailRoute {
    switch (args.kind) {
      case SavedDetailSubcategoryKind.activities:
        return AppRoutes.activityDetail;
      case SavedDetailSubcategoryKind.health:
        return AppRoutes.healthDetail;
      case SavedDetailSubcategoryKind.networking:
        return AppRoutes.networkingDetail;
    }
  }

  void _openDetail(BuildContext context, SavedDetailItem item) {
    Navigator.pushNamed(context, _detailRoute, arguments: item);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final items = _items(provider);

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppValues.screenHorizontalPadding,
                10,
                AppValues.screenHorizontalPadding,
                20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppScreenHeader(title: args.item.title),
                  16.vSpace,
                  if (items.isEmpty)
                    EmptyState(
                      message: AppStrings.currentlyUnavailable,
                      icon: _emptyIcon,
                    )
                  else
                    ...items.map((item) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: context.rs(10, min: 10, max: 12),
                        ),
                        child: SavedDetailCard(
                          item: item,
                          isLiked: provider.isSavedItemLiked(item.id),
                          isLikePending: provider.isSavedItemPending(item.id),
                          onLikeTap: () =>
                              provider.toggleSavedItemLike(item.id),
                          onTap: () => _openDetail(context, item),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
