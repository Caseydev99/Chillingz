import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_screen_header.dart';
import '../../../widgets/content_loading_placeholder.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/home_filter_sheet.dart';
import '../../../widgets/image_category_card.dart';
import '../../../widgets/music_filter_chip.dart';
import '../../../widgets/saved_detail_card.dart';
import '../../../widgets/saved_search_bar.dart';
import '../models/food_cuisine_item.dart';
import '../models/saved_detail_item.dart';
import '../providers/home_provider.dart';
import 'saved_detail_subcategory_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  void _openDetail(BuildContext context, SavedDetailItem item) {
    Navigator.pushNamed(context, AppRoutes.activityDetail, arguments: item);
  }

  void _openSubcategory(BuildContext context, FoodCuisineItem item) {
    Navigator.pushNamed(
      context,
      AppRoutes.savedDetailSubcategory,
      arguments: SavedDetailSubcategoryArgs(
        item: item,
        kind: SavedDetailSubcategoryKind.activities,
      ),
    );
  }

  Future<void> _showFilterSheet(
    BuildContext context,
    HomeProvider provider,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => HomeFilterSheet(
        title: AppStrings.filterHome,
        filters: provider.activityFilters,
        selectedFilter: provider.selectedActivityFilter,
        onSelected: provider.updateActivityFilter,
        onReset: () => provider.updateActivityFilter(''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final items = provider.activityItems;
        final subcategories = provider.activitySubcategories;
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
                  const AppScreenHeader(title: AppStrings.activities),
                  18.vSpace,
                  Text(
                    AppStrings.activitiesScreenTitle,
                    style: TextStyle(
                      fontSize: context.rs(18, min: 17, max: 20),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  14.vSpace,
                  SavedSearchBar(
                    hintText: 'Search activities',
                    onChanged: provider.updateActivitySearchQuery,
                    onFilterTap: () => _showFilterSheet(context, provider),
                  ),
                  12.vSpace,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: provider.activityFilters.map((filter) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: context.rs(8, min: 7, max: 9),
                          ),
                          child: GestureDetector(
                            onTap: () => provider.updateActivityFilter(filter),
                            child: MusicFilterChip(
                              label: filter,
                              isSelected:
                                  provider.selectedActivityFilter == filter,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  18.vSpace,
                  if (subcategories.isNotEmpty) ...[
                    Text(
                      'Subcategories',
                      style: TextStyle(
                        fontSize: context.rs(16, min: 15, max: 17),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    10.vSpace,
                    GridView.builder(
                      itemCount: subcategories.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.16,
                          ),
                      itemBuilder: (context, index) {
                        final item = subcategories[index];
                        return ImageCategoryCard(
                          title: item.title,
                          imagePath: item.imagePath,
                          onTap: () => _openSubcategory(context, item),
                        );
                      },
                    ),
                    18.vSpace,
                  ],
                  Text(
                    AppStrings.mustTryActivities,
                    style: TextStyle(
                      fontSize: context.rs(16, min: 15, max: 17),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  12.vSpace,
                  if (items.isEmpty)
                    provider.isLoadingPublicData
                        ? const ContentLoadingPlaceholder(itemCount: 3)
                        : EmptyState(
                            message: AppStrings.currentlyUnavailable,
                            icon: Icons.explore_outlined,
                            actionLabel: provider.publicDataError == null
                                ? null
                                : 'Retry',
                            onAction: provider.publicDataError == null
                                ? null
                                : () => provider.loadPublicData(
                                    forceRefresh: true,
                                  ),
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
