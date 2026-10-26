import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/app_screen_header.dart';
import '../../../widgets/content_links_button.dart';
import '../../../widgets/music_event_overview.dart';
import '../../../widgets/social_post_card.dart';
import '../models/music_event_item.dart';
import '../providers/home_provider.dart';

class MusicEventDetailScreen extends StatelessWidget {
  const MusicEventDetailScreen({super.key, required this.item});

  final MusicEventItem item;

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppValues.screenHorizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  8.vSpace,
                  AppScreenHeader(title: item.title),
                  16.vSpace,
                  MusicEventOverview(
                    item: item,
                    isLiked: provider.isSavedItemLiked(item.id),
                    isLikePending: provider.isSavedItemPending(item.id),
                    onLikeTap: () => provider.toggleSavedItemLike(item.id),
                  ),
                  16.vSpace,
                  ContentLinksButton(
                    websiteLink: item.websiteLink,
                    mapLink: item.mapLink,
                    ticketLink: item.ticketLink,
                  ),
                  22.vSpace,
                  Text(
                    AppStrings.socialPosts,
                    style: TextStyle(
                      fontSize: context.rs(18, min: 17, max: 20),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  14.vSpace,
                  if (provider.socialPostsForMusicEvent(item).isEmpty)
                    const EmptyState(
                      message: AppStrings.currentlyUnavailable,
                      icon: Icons.forum_outlined,
                    )
                  else
                    ...provider.socialPostsForMusicEvent(item).map((post) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: context.rs(14, min: 12, max: 16),
                        ),
                        child: SocialPostCard(item: post),
                      );
                    }),
                  20.vSpace,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
