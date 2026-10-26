import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
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

class HealthWellbeingScreen extends StatefulWidget {
  const HealthWellbeingScreen({super.key});

  @override
  State<HealthWellbeingScreen> createState() => _HealthWellbeingScreenState();
}

class _HealthWellbeingScreenState extends State<HealthWellbeingScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<HomeProvider>();
    _searchController = TextEditingController(text: provider.healthSearchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext context, SavedDetailItem item) {
    Navigator.pushNamed(context, AppRoutes.healthDetail, arguments: item);
  }

  void _openSubcategory(BuildContext context, FoodCuisineItem item) {
    Navigator.pushNamed(
      context,
      AppRoutes.savedDetailSubcategory,
      arguments: SavedDetailSubcategoryArgs(
        item: item,
        kind: SavedDetailSubcategoryKind.health,
      ),
    );
  }

  Future<void> _showFilterSheet(HomeProvider provider) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => HomeFilterSheet(
        title: AppStrings.filterHome,
        filters: provider.healthFilters,
        selectedFilter: provider.selectedHealthFilter,
        onSelected: provider.updateHealthFilter,
        onReset: () {
          if (provider.healthFilters.isNotEmpty) {
            provider.updateHealthFilter(provider.healthFilters.first);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final items = provider.healthItems;
        final subcategories = provider.healthSubcategories;
        if (_searchController.text != provider.healthSearchQuery) {
          _searchController.value = _searchController.value.copyWith(
            text: provider.healthSearchQuery,
            selection: TextSelection.collapsed(
              offset: provider.healthSearchQuery.length,
            ),
          );
        }

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
                  const AppScreenHeader(title: AppStrings.healthWellbeing),
                  16.vSpace,
                  Text(
                    AppStrings.healthWellbeingScreenTitle,
                    style: TextStyle(
                      fontSize: context.rs(19, min: 18, max: 20),
                      fontWeight: FontWeight.w500,
                      height: 1.08,
                    ),
                  ),
                  18.vSpace,
                  SavedSearchBar(
                    controller: _searchController,
                    onChanged: provider.updateHealthSearchQuery,
                    hintText: 'Search.....',
                    height: context.rs(52, min: 50, max: 54),
                    iconSize: context.rs(26, min: 24, max: 28),
                    filterButtonSize: context.rs(40, min: 38, max: 42),
                    filterIconSize: context.rs(18, min: 17, max: 19),
                    backgroundColor: AppColors.inputFill,
                    textColor: AppColors.textPrimary,
                    filterButtonColor: AppColors.primaryLight,
                    borderRadius: context.rs(26, min: 25, max: 27),
                    leftPadding: context.rs(16, min: 15, max: 17),
                    rightPadding: context.rs(10, min: 9, max: 11),
                    onFilterTap: () => _showFilterSheet(provider),
                  ),
                  16.vSpace,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: provider.healthFilters.map((filter) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: context.rs(8, min: 7, max: 9),
                          ),
                          child: GestureDetector(
                            onTap: () => provider.updateHealthFilter(filter),
                            child: MusicFilterChip(
                              label: filter,
                              isSelected:
                                  provider.selectedHealthFilter == filter,
                              selectedBackgroundColor: AppColors.primary,
                              selectedBorderColor: AppColors.primary,
                              selectedTextColor: AppColors.white,
                              unselectedBackgroundColor: AppColors.background,
                              unselectedBorderColor: const Color(0xFF8A44D8),
                              unselectedTextColor: AppColors.textPrimary,
                              horizontalPadding: context.rs(
                                15,
                                min: 14,
                                max: 16,
                              ),
                              verticalPadding: context.rs(8, min: 7, max: 8),
                              fontSize: context.rs(11.8, min: 11.3, max: 12),
                              borderWidth: 1.1,
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
                    AppStrings.healthWellbeing,
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
                            icon: Icons.spa_outlined,
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
