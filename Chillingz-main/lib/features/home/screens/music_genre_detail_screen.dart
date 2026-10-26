import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_screen_header.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/music_event_card.dart';
import '../models/music_event_item.dart';
import '../models/music_genre_item.dart';
import '../providers/home_provider.dart';

class MusicGenreDetailScreen extends StatelessWidget {
  const MusicGenreDetailScreen({super.key, required this.genre});

  final MusicGenreItem genre;

  void _openEvent(BuildContext context, MusicEventItem item) {
    Navigator.pushNamed(context, AppRoutes.musicEventDetail, arguments: item);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final items = provider.musicEventsForGenre(genre);

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
                  AppScreenHeader(title: genre.title),
                  16.vSpace,
                  if (items.isEmpty)
                    EmptyState(
                      message: AppStrings.currentlyUnavailable,
                      icon: Icons.music_note_outlined,
                    )
                  else
                    ...items.map((item) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: context.rs(12, min: 10, max: 14),
                        ),
                        child: MusicEventCard(
                          item: item,
                          isCompact: true,
                          featuredStyle: true,
                          isLiked: provider.isSavedItemLiked(item.id),
                          isLikePending: provider.isSavedItemPending(item.id),
                          onLikeTap: () =>
                              provider.toggleSavedItemLike(item.id),
                          onTap: () => _openEvent(context, item),
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
