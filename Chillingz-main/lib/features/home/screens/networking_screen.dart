import 'dart:async';

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

class NetworkingScreen extends StatefulWidget {
  const NetworkingScreen({super.key});

  @override
  State<NetworkingScreen> createState() => _NetworkingScreenState();
}

class _NetworkingScreenState extends State<NetworkingScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<HomeProvider>();
    _searchController = TextEditingController(
      text: provider.networkingSearchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext context, SavedDetailItem item) {
    Navigator.pushNamed(context, AppRoutes.networkingDetail, arguments: item);
  }

  void _openSubcategory(BuildContext context, FoodCuisineItem item) {
    Navigator.pushNamed(
      context,
      AppRoutes.savedDetailSubcategory,
      arguments: SavedDetailSubcategoryArgs(
        item: item,
        kind: SavedDetailSubcategoryKind.networking,
      ),
    );
  }

  Future<void> _showFilterSheet(HomeProvider provider) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => HomeFilterSheet(
        title: AppStrings.filterHome,
        filters: provider.networkingFilters,
        selectedFilter: provider.selectedNetworkingFilter,
        onSelected: provider.updateNetworkingFilter,
        onReset: () {
          if (provider.networkingFilters.isNotEmpty) {
            provider.updateNetworkingFilter(provider.networkingFilters.first);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final items = provider.networkingItems;
        final subcategories = provider.networkingSubcategories;
        if (_searchController.text != provider.networkingSearchQuery) {
          _searchController.value = _searchController.value.copyWith(
            text: provider.networkingSearchQuery,
            selection: TextSelection.collapsed(
              offset: provider.networkingSearchQuery.length,
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
                  const AppScreenHeader(title: AppStrings.networking),
                  16.vSpace,
                  Text(
                    AppStrings.networkingScreenTitle,
                    style: TextStyle(
                      fontSize: context.rs(19, min: 18, max: 20),
                      fontWeight: FontWeight.w500,
                      height: 1.08,
                    ),
                  ),
                  18.vSpace,
                  SavedSearchBar(
                    controller: _searchController,
                    onChanged: provider.updateNetworkingSearchQuery,
                    hintText: 'Search....',
                    height: context.rs(52, min: 50, max: 54),
                    iconSize: context.rs(25, min: 23, max: 27),
                    filterButtonSize: context.rs(38, min: 36, max: 40),
                    filterIconSize: context.rs(17, min: 16, max: 18),
                    backgroundColor: AppColors.inputFill,
                    textColor: AppColors.textPrimary,
                    filterButtonColor: AppColors.primaryLight,
                    borderRadius: context.rs(26, min: 25, max: 27),
                    leftPadding: context.rs(16, min: 15, max: 17),
                    rightPadding: context.rs(10, min: 9, max: 11),
                    onFilterTap: () => _showFilterSheet(provider),
                  ),
                  14.vSpace,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: provider.networkingFilters.map((filter) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: context.rs(8, min: 7, max: 9),
                          ),
                          child: GestureDetector(
                            onTap: () =>
                                provider.updateNetworkingFilter(filter),
                            child: MusicFilterChip(
                              label: filter,
                              isSelected:
                                  provider.selectedNetworkingFilter == filter,
                              selectedBackgroundColor: AppColors.primary,
                              selectedBorderColor: AppColors.primary,
                              selectedTextColor: AppColors.white,
                              unselectedBackgroundColor: AppColors.background,
                              unselectedBorderColor: const Color(0xFF8A44D8),
                              unselectedTextColor: AppColors.textPrimary,
                              horizontalPadding: context.rs(
                                14,
                                min: 13,
                                max: 15,
                              ),
                              verticalPadding: context.rs(
                                7,
                                min: 6.5,
                                max: 7.5,
                              ),
                              fontSize: context.rs(11.2, min: 10.8, max: 11.6),
                              borderWidth: 1,
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
                    AppStrings.networking,
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
                            icon: Icons.groups_outlined,
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
