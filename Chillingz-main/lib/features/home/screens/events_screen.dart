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
import '../../../widgets/music_event_card.dart';
import '../../../widgets/music_filter_chip.dart';
import '../../../widgets/saved_search_bar.dart';
import '../models/music_event_item.dart';
import '../providers/home_provider.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  void _openDetail(BuildContext context, MusicEventItem item) {
    Navigator.pushNamed(
      context,
      AppRoutes.eventDetail,
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
        filters: provider.eventFilters,
        selectedFilter: provider.selectedEventFilter,
        onSelected: provider.updateEventFilter,
        onReset: () {
          if (provider.eventFilters.isNotEmpty) {
            provider.updateEventFilter(provider.eventFilters.first);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final items = provider.eventItems;
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
                  const AppScreenHeader(title: AppStrings.events),
                  16.vSpace,
                  Text(
                    AppStrings.eventsScreenTitle,
                    style: TextStyle(
                      fontSize: context.rs(18, min: 17, max: 20),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  14.vSpace,
                  SavedSearchBar(
                    hintText: AppStrings.searchEvents,
                    onChanged: provider.updateEventSearchQuery,
                    onFilterTap: () => _showFilterSheet(context, provider),
                  ),
                  12.vSpace,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: provider.eventFilters.map((filter) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: context.rs(8, min: 7, max: 9),
                          ),
                          child: GestureDetector(
                            onTap: () => provider.updateEventFilter(filter),
                            child: MusicFilterChip(
                              label: filter,
                              isSelected:
                                  provider.selectedEventFilter == filter,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  16.vSpace,
                  Text(
                    AppStrings.nearbyEvents,
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
                            icon: Icons.event_outlined,
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
                          bottom: context.rs(12, min: 10, max: 14),
                        ),
                        child: MusicEventCard(
                          item: item,
                          eventStyle: true,
                          isLiked: provider.isSavedItemLiked(item.id),
                          isLikePending: provider.isSavedItemPending(item.id),
                          onLikeTap: () =>
                              provider.toggleSavedItemLike(item.id),
                          backgroundColor: AppColors.eventCardBackground,
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
