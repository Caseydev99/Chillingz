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
import '../../../widgets/music_genre_card.dart';
import '../../../widgets/saved_search_bar.dart';
import '../models/music_event_item.dart';
import '../models/music_genre_item.dart';
import '../providers/home_provider.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<HomeProvider>().loadPublicData();
    });
  }

  void _openEvent(BuildContext context, MusicEventItem item) {
    Navigator.pushNamed(
      context,
      AppRoutes.musicEventDetail,
      arguments: item,
    );
  }

  void _openGenre(BuildContext context, MusicGenreItem item) {
    Navigator.pushNamed(
      context,
      AppRoutes.musicGenreDetail,
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
        filters: provider.musicFilters,
        selectedFilter: provider.selectedMusicFilter,
        onSelected: provider.updateMusicFilter,
        onReset: () {
          if (provider.musicFilters.isNotEmpty) {
            provider.updateMusicFilter(provider.musicFilters.first);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final genres = provider.musicGenres;
        final events = provider.musicEvents;
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
                  const AppScreenHeader(title: AppStrings.music),
                  18.vSpace,
                  Text(
                    AppStrings.musicScreenTitle,
                    style: TextStyle(
                      fontSize: context.rs(18, min: 17, max: 20),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.15,
                    ),
                  ),
                  14.vSpace,
                  SavedSearchBar(
                    hintText: AppStrings.homeSearchHint,
                    onChanged: provider.updateMusicSearchQuery,
                    onFilterTap: () => _showFilterSheet(context, provider),
                  ),
                  12.vSpace,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: provider.musicFilters.map((filter) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: context.rs(8, min: 7, max: 9),
                          ),
                          child: GestureDetector(
                            onTap: () => provider.updateMusicFilter(filter),
                            child: MusicFilterChip(
                              label: filter,
                              isSelected:
                                  provider.selectedMusicFilter == filter,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  18.vSpace,
                  Text(
                    AppStrings.genres,
                    style: TextStyle(
                      fontSize: context.rs(16, min: 15, max: 17),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  10.vSpace,
                  if (genres.isEmpty)
                    provider.isLoadingPublicData
                        ? const ContentLoadingPlaceholder(
                            itemCount: 4,
                            grid: true,
                          )
                        : EmptyState(
                            message: AppStrings.currentlyUnavailable,
                            icon: Icons.music_note_outlined,
                            topPadding: context.rs(16, min: 14, max: 20),
                          )
                  else
                    GridView.builder(
                      itemCount: genres.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.48,
                          ),
                      itemBuilder: (context, index) {
                        final item = genres[index];
                        return MusicGenreCard(
                          item: item,
                          onTap: () => _openGenre(context, item),
                        );
                      },
                    ),
                  18.vSpace,
                  Text(
                    AppStrings.featuredEvents,
                    style: TextStyle(
                      fontSize: context.rs(16, min: 15, max: 17),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  10.vSpace,
                  if (events.isEmpty)
                    provider.isLoadingPublicData
                        ? const ContentLoadingPlaceholder(itemCount: 3)
                        : EmptyState(
                            message: AppStrings.currentlyUnavailable,
                            icon: Icons.event_note_outlined,
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
                    SizedBox(
                      height: context.rs(206, min: 196, max: 214),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: events.length,
                        separatorBuilder: (context, index) =>
                            context.rs(10, min: 10, max: 12).hSpace,
                        itemBuilder: (context, index) {
                          final item = events[index];
                          return MusicEventCard(
                            item: item,
                            isCompact: true,
                            isLiked: provider.isSavedItemLiked(item.id),
                            isLikePending: provider.isSavedItemPending(item.id),
                            onLikeTap: () =>
                                provider.toggleSavedItemLike(item.id),
                            onTap: () => _openEvent(context, item),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
