import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/home_filter_sheet.dart';
import '../../../widgets/saved_events_section.dart';
import '../../../widgets/saved_header_section.dart';
import '../../../widgets/saved_items_section.dart';
import '../models/saved_detail_item.dart';
import '../models/saved_event_item.dart';
import '../providers/home_provider.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<HomeProvider>();
    _searchController = TextEditingController(text: provider.savedSearchQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final provider = context.read<HomeProvider>();
      provider.loadPublicData();
      provider.loadSavedItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSavedEvent(
    BuildContext context,
    HomeProvider provider,
    SavedEventItem item,
  ) {
    Navigator.pushNamed(
      context,
      AppRoutes.musicEventDetail,
      arguments: provider.savedEventToMusicEvent(item),
    );
  }

  Future<void> _showFilterSheet(HomeProvider provider) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => HomeFilterSheet(
        title: AppStrings.filterHome,
        filters: provider.savedFilters,
        selectedFilter: provider.selectedSavedFilter,
        onSelected: provider.updateSavedFilter,
        onReset: () => provider.updateSavedFilter(AppStrings.all),
      ),
    );
  }

  void _openSavedActivity(BuildContext context, SavedDetailItem item) {
    Navigator.pushNamed(context, AppRoutes.activityDetail, arguments: item);
  }

  void _openSavedFood(BuildContext context, SavedDetailItem item) {
    Navigator.pushNamed(context, AppRoutes.foodPlaceDetail, arguments: item);
  }

  void _openSavedHealth(BuildContext context, SavedDetailItem item) {
    Navigator.pushNamed(context, AppRoutes.healthDetail, arguments: item);
  }

  void _openSavedNetworking(BuildContext context, SavedDetailItem item) {
    Navigator.pushNamed(context, AppRoutes.networkingDetail, arguments: item);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        if (_searchController.text != provider.savedSearchQuery) {
          _searchController.value = _searchController.value.copyWith(
            text: provider.savedSearchQuery,
            selection: TextSelection.collapsed(
              offset: provider.savedSearchQuery.length,
            ),
          );
        }
        final horizontalPadding = context.rs(16, min: 14, max: 20);
        final hasSavedItems =
            provider.filteredSavedEvents.isNotEmpty ||
            provider.savedActivities.isNotEmpty ||
            provider.savedFoodAndDrinks.isNotEmpty ||
            provider.savedHealthWellbeing.isNotEmpty ||
            provider.savedNetworking.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    context.rs(8, min: 6, max: 12),
                    horizontalPadding,
                    0,
                  ),
                  child: SavedHeaderSection(
                    controller: _searchController,
                    onChanged: provider.updateSavedSearchQuery,
                    onFilterTap: () => _showFilterSheet(provider),
                  ),
                ),
                context.rs(14, min: 12, max: 18).vSpace,
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      context.rs(18, min: 16, max: 22),
                    ),
                    children: [
                      if (provider.isLoadingSavedItems && !hasSavedItems)
                        Padding(
                          padding: EdgeInsets.only(
                            top: context.rs(80, min: 72, max: 96),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (!hasSavedItems)
                        Padding(
                          padding: EdgeInsets.only(
                            top: context.rs(80, min: 72, max: 96),
                          ),
                          child: const EmptyState(
                            message: AppStrings.currentlyUnavailable,
                            icon: Icons.bookmark_border_outlined,
                            topPadding: 0,
                          ),
                        ),
                      SavedEventsSection(
                        title: AppStrings.savedEvents,
                        items: provider.filteredSavedEvents,
                        likedIds: provider.likedSavedItems,
                        onToggle: provider.toggleSavedItemLike,
                        isPending: provider.isSavedItemPending,
                        onItemTap: (item) =>
                            _openSavedEvent(context, provider, item),
                      ),
                      context.rs(18, min: 16, max: 20).vSpace,
                      SavedItemsSection(
                        title: AppStrings.savedActivities,
                        items: provider.savedActivities,
                        isLiked: provider.isSavedItemLiked,
                        onToggle: provider.toggleSavedItemLike,
                        isPending: provider.isSavedItemPending,
                        onItemTap: (item) => _openSavedActivity(context, item),
                        trailingLabel: AppStrings.seeAll,
                        onTrailingTap: () =>
                            Navigator.pushNamed(context, AppRoutes.activities),
                      ),
                      context.rs(18, min: 16, max: 20).vSpace,
                      SavedItemsSection(
                        title: AppStrings.savedFoodDrink,
                        items: provider.savedFoodAndDrinks,
                        isLiked: provider.isSavedItemLiked,
                        onToggle: provider.toggleSavedItemLike,
                        isPending: provider.isSavedItemPending,
                        onItemTap: (item) => _openSavedFood(context, item),
                        trailingLabel: AppStrings.seeAll,
                        onTrailingTap: () =>
                            Navigator.pushNamed(context, AppRoutes.foodDrink),
                      ),
                      context.rs(18, min: 16, max: 20).vSpace,
                      SavedItemsSection(
                        title: AppStrings.savedHealthWellbeing,
                        items: provider.savedHealthWellbeing,
                        isLiked: provider.isSavedItemLiked,
                        onToggle: provider.toggleSavedItemLike,
                        isPending: provider.isSavedItemPending,
                        onItemTap: (item) => _openSavedHealth(context, item),
                        trailingLabel: AppStrings.seeAll,
                        onTrailingTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.healthWellbeing,
                        ),
                      ),
                      context.rs(18, min: 16, max: 20).vSpace,
                      SavedItemsSection(
                        title: AppStrings.savedNetworking,
                        items: provider.savedNetworking,
                        isLiked: provider.isSavedItemLiked,
                        onToggle: provider.toggleSavedItemLike,
                        isPending: provider.isSavedItemPending,
                        onItemTap: (item) =>
                            _openSavedNetworking(context, item),
                        trailingLabel: AppStrings.seeAll,
                        onTrailingTap: () =>
                            Navigator.pushNamed(context, AppRoutes.networking),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
