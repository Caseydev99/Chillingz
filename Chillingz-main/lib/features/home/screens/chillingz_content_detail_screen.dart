import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/app_image.dart';
import '../../../widgets/app_screen_header.dart';
import '../../../widgets/content_links_button.dart';
import '../../../widgets/social_post_card.dart';
import '../models/chillingz_content_item.dart';
import '../models/social_post_item.dart';

class ChillingzContentDetailScreen extends StatelessWidget {
  const ChillingzContentDetailScreen({
    super.key,
    required this.item,
    required this.fallbackImage,
  });

  final ChillingzContentItem item;
  final String fallbackImage;

  @override
  Widget build(BuildContext context) {
    final title = _safeString(() => item.title);
    final description = _safeString(() => item.description);
    final imagePath = _safeString(() => item.imagePath);
    final priceLabel = _safeString(() => item.priceLabel);
    final rating = _safeString(() => item.rating);
    final status = _safeString(() => item.status);
    final image = imagePath.isNotEmpty ? imagePath : fallbackImage;
    final radius = context.rs(14, min: 12, max: 16);
    final websiteLink = _safeString(() => item.websiteLink);
    final mapLink = _safeString(() => item.mapLink);
    final ticketLink = _safeString(() => item.ticketLink);
    final venueName = _safeString(() => item.venueName);
    final socialPosts = _safeSocialPosts(() => item.socialPosts);
    final hasDetails =
        venueName.isNotEmpty ||
        priceLabel.isNotEmpty ||
        rating.isNotEmpty ||
        status.isNotEmpty ||
        description.isNotEmpty;
    final hasLinks =
        websiteLink.isNotEmpty || mapLink.isNotEmpty || ticketLink.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppValues.screenHorizontalPadding,
            8,
            AppValues.screenHorizontalPadding,
            22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppScreenHeader(title: title),
              16.vSpace,
              _HeroImage(
                image: image,
                title: title,
                venueName: venueName,
                radius: radius,
              ),
              if (hasDetails) ...[
                16.vSpace,
                _DetailsPanel(
                  description: description,
                  venueName: venueName,
                  priceLabel: priceLabel,
                  rating: rating,
                  status: status,
                ),
              ],
              if (hasLinks) ...[
                14.vSpace,
                _ActionPanel(
                  child: ContentLinksButton(
                    websiteLink: websiteLink,
                    mapLink: mapLink,
                    ticketLink: ticketLink,
                  ),
                ),
              ],
              if (socialPosts.isNotEmpty) ...[
                24.vSpace,
                Text(
                  AppStrings.socialPosts,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: context.rs(18, min: 17, max: 20),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                14.vSpace,
                ...socialPosts.map((post) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: context.rs(14, min: 12, max: 16),
                    ),
                    child: SocialPostCard(item: post),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.image,
    required this.title,
    required this.venueName,
    required this.radius,
  });

  final String image;
  final String title;
  final String venueName;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 1.08,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppImage(source: image, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x33000000),
                    Color(0xCC000000),
                  ],
                  stops: [0.44, 0.67, 1],
                ),
              ),
            ),
            Positioned(
              left: context.rs(16, min: 14, max: 18),
              right: context.rs(16, min: 14, max: 18),
              bottom: context.rs(16, min: 14, max: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: context.rs(24, min: 22, max: 28),
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  if (venueName.isNotEmpty) ...[
                    context.rs(8, min: 7, max: 9).vSpace,
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          color: AppColors.white.withOpacity(0.88),
                          size: context.rs(15, min: 14, max: 16),
                        ),
                        context.rs(5, min: 4, max: 6).hSpace,
                        Expanded(
                          child: Text(
                            venueName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.9),
                              fontSize: context.rs(12.5, min: 12, max: 13.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.description,
    required this.venueName,
    required this.priceLabel,
    required this.rating,
    required this.status,
  });

  final String description;
  final String venueName;
  final String priceLabel;
  final String rating;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.rs(14, min: 13, max: 16)),
      decoration: BoxDecoration(
        color: AppColors.settingsTileBackground,
        borderRadius: BorderRadius.circular(context.rs(14, min: 12, max: 16)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: context.rs(16, min: 15, max: 17),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (description.isNotEmpty) ...[
            context.rs(10, min: 9, max: 12).vSpace,
            Text(
              description,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: context.rs(13.5, min: 13, max: 14.5),
                height: 1.42,
              ),
            ),
          ],
          context.rs(12, min: 10, max: 14).vSpace,
          Wrap(
            spacing: context.rs(8, min: 7, max: 10),
            runSpacing: context.rs(8, min: 7, max: 10),
            children: [
              if (venueName.isNotEmpty)
                _DetailChip(icon: Icons.place_outlined, label: venueName),
              if (priceLabel.isNotEmpty)
                _DetailChip(icon: Icons.payments_outlined, label: priceLabel),
              if (rating.isNotEmpty)
                _DetailChip(icon: Icons.star_rounded, label: rating),
              if (status.isNotEmpty)
                _DetailChip(
                  icon: Icons.check_circle_outline_rounded,
                  label: status,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.rs(12, min: 11, max: 14)),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(context.rs(14, min: 12, max: 16)),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

String _safeString(Object? Function() read) {
  try {
    return read()?.toString().trim() ?? '';
  } catch (_) {
    return '';
  }
}

List<SocialPostItem> _safeSocialPosts(Object? Function() read) {
  try {
    final value = read();
    if (value is List<SocialPostItem>) {
      return value;
    }
  } catch (_) {
    return const <SocialPostItem>[];
  }
  return const <SocialPostItem>[];
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(11, min: 10, max: 12),
        vertical: context.rs(7, min: 6, max: 8),
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: context.rs(15, min: 14, max: 16),
            color: AppColors.textSecondary,
          ),
          context.rs(6, min: 5, max: 7).hSpace,
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: context.rs(12, min: 11.5, max: 13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
