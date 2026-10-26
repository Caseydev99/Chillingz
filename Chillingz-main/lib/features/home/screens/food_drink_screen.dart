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

class FoodDrinkScreen extends StatefulWidget {
  const FoodDrinkScreen({super.key});

  @override
  State<FoodDrinkScreen> createState() => _FoodDrinkScreenState();
}

class _FoodDrinkScreenState extends State<FoodDrinkScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    context.read<HomeProvider>().updateFoodSearchQuery('', notify: false);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCuisine(BuildContext context, FoodCuisineItem item) {
    Navigator.pushNamed(
      context,
      AppRoutes.foodCuisineDetail,
      arguments: item,
    );
  }

  void _openPlace(BuildContext context, SavedDetailItem item) {
    Navigator.pushNamed(
      context,
      AppRoutes.foodPlaceDetail,
      arguments: item,
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
        filters: provider.foodFilters,
        selectedFilter: provider.selectedFoodFilter,
        onSelected: provider.updateFoodFilter,
        onReset: () => provider.updateFoodFilter(''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final cuisines = provider.foodCuisines;
        final places = provider.foodPlaces;
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
                  const AppScreenHeader(title: AppStrings.foodDrink),
                  16.vSpace,
                  Text(
                    AppStrings.foodDrinkScreenTitle,
                    style: TextStyle(
                      fontSize: context.rs(18, min: 17, max: 20),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  14.vSpace,
                  SavedSearchBar(
                    controller: _searchController,
                    hintText: AppStrings.searchRestaurants,
                    onChanged: provider.updateFoodSearchQuery,
                    onFilterTap: () => _showFilterSheet(context, provider),
                  ),
                  12.vSpace,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: provider.foodFilters.map((filter) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: context.rs(8, min: 7, max: 9),
                          ),
                          child: GestureDetector(
                            onTap: () => provider.updateFoodFilter(filter),
                            child: MusicFilterChip(
                              label: filter,
                              isSelected: provider.selectedFoodFilter == filter,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  16.vSpace,
                  Text(
                    AppStrings.cuisines,
                    style: TextStyle(
                      fontSize: context.rs(16, min: 15, max: 17),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  10.vSpace,
                  if (cuisines.isEmpty)
                    provider.isLoadingPublicData
                        ? const ContentLoadingPlaceholder(
                            itemCount: 4,
                            grid: true,
                          )
                        : EmptyState(
                            message: AppStrings.currentlyUnavailable,
                            icon: Icons.restaurant_menu_outlined,
                            topPadding: context.rs(16, min: 14, max: 20),
                          )
                  else
                    GridView.builder(
                      itemCount: cuisines.length,
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
                        final item = cuisines[index];
                        return ImageCategoryCard(
                          title: item.title,
                          imagePath: item.imagePath,
                          onTap: () => _openCuisine(context, item),
                        );
                      },
                    ),
                  16.vSpace,
                  Text(
                    AppStrings.popularPlaces,
                    style: TextStyle(
                      fontSize: context.rs(16, min: 15, max: 17),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  12.vSpace,
                  if (places.isEmpty)
                    provider.isLoadingPublicData
                        ? const ContentLoadingPlaceholder(itemCount: 3)
                        : EmptyState(
                            message: AppStrings.currentlyUnavailable,
                            icon: Icons.local_dining_outlined,
                            actionLabel: provider.publicDataError == null
                                ? null
                                : 'Retry',
                            onAction: provider.publicDataError == null
                                ? null
                                : () => provider.loadPublicData(
                                    forceRefresh: true,
                                  ),
                            topPadding: context.rs(16, min: 14, max: 20),
                          )
                  else
                    ...places.map((item) {
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
                          onTap: () => _openPlace(context, item),
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
