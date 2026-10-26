import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/app_screen_header.dart';
import '../../../widgets/content_links_button.dart';
import '../../../widgets/saved_detail_overview.dart';
import '../../../widgets/social_post_card.dart';
import '../models/saved_detail_item.dart';
import '../providers/home_provider.dart';

class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key, required this.item});

  final SavedDetailItem item;

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
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
                  AppScreenHeader(title: item.title),
                  18.vSpace,
                  SavedDetailOverview(
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
                  if (item.socialPosts.isEmpty)
                    const EmptyState(
                      message: AppStrings.currentlyUnavailable,
                      icon: Icons.forum_outlined,
                    )
                  else
                    ...item.socialPosts.map((post) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: context.rs(14, min: 12, max: 16),
                        ),
                        child: SocialPostCard(item: post),
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
