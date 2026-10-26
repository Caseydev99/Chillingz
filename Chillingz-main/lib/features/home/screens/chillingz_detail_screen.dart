import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/app_image.dart';
import '../../../widgets/app_screen_header.dart';
import '../../../widgets/empty_state.dart';
import '../models/chillingz_content_item.dart';
import '../models/home_discovery_item.dart';
import '../models/social_post_item.dart';
import 'chillingz_content_detail_screen.dart';

class ChillingzDetailScreen extends StatelessWidget {
  const ChillingzDetailScreen({super.key, required this.item});

  final HomeDiscoveryItem item;

  void _openContentDetail(BuildContext context, ChillingzContentItem content) {
    final safeContent = _safeChillingzContent(content);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChillingzContentDetailScreen(
          item: safeContent,
          fallbackImage: _safeString(() => item.imagePath),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = context.rs(14, min: 12, max: 16);
    final title = _safeString(() => item.title);
    final imagePath = _safeString(() => item.imagePath);
    final tag = _safeString(() => item.tag);
    final contentItems = _safeChillingzContentItems(() => item.contentItems);
    final isNature = _safeBool(() => item.isNature);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppValues.screenHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              8.vSpace,
              AppScreenHeader(title: title),
              16.vSpace,
              ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: AspectRatio(
                  aspectRatio: isNature ? 1.45 : 1.55,
                  child: AppImage(source: imagePath, fit: BoxFit.cover),
                ),
              ),
              if (tag.isNotEmpty) ...[
                12.vSpace,
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.rs(12, min: 11, max: 14),
                      vertical: context.rs(7, min: 6, max: 8),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.rs(12, min: 11.5, max: 13),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
              22.vSpace,
              Text(
                'Chillingz Content',
                style: TextStyle(
                  fontSize: context.rs(18, min: 17, max: 20),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              14.vSpace,
              if (contentItems.isEmpty)
                const EmptyState(
                  message: AppStrings.currentlyUnavailable,
                  icon: Icons.auto_awesome_outlined,
                )
              else
                ...contentItems.map((content) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: context.rs(14, min: 12, max: 16),
                    ),
                    child: _ChillingzContentCard(
                      item: content,
                      fallbackImage: imagePath,
                      onTap: () => _openContentDetail(context, content),
                    ),
                  );
                }),
              20.vSpace,
            ],
          ),
        ),
      ),
    );
  }
}

class _ChillingzContentCard extends StatelessWidget {
  const _ChillingzContentCard({
    required this.item,
    required this.fallbackImage,
    required this.onTap,
  });

  final ChillingzContentItem item;
  final String fallbackImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = context.rs(12, min: 11, max: 14);
    final title = _safeString(() => item.title);
    final description = _safeString(() => item.description);
    final imagePath = _safeString(() => item.imagePath);
    final priceLabel = _safeString(() => item.priceLabel);
    final rating = _safeString(() => item.rating);
    final venueName = _safeString(() => item.venueName);
    final image = imagePath.isNotEmpty ? imagePath : fallbackImage;

    return Material(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.75,
                child: AppImage(source: image, fit: BoxFit.cover),
              ),
              Padding(
                padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: context.rs(16, min: 15, max: 17),
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        context.rs(10, min: 8, max: 12).hSpace,
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                          size: context.rs(24, min: 22, max: 26),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      context.rs(8, min: 7, max: 9).vSpace,
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: context.rs(13, min: 12.5, max: 14),
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ],
                    context.rs(12, min: 10, max: 14).vSpace,
                    Wrap(
                      spacing: context.rs(8, min: 7, max: 10),
                      runSpacing: context.rs(8, min: 7, max: 10),
                      children: [
                        if (venueName.isNotEmpty)
                          _ContentMetaChip(
                            icon: Icons.place_outlined,
                            label: venueName,
                          ),
                        if (priceLabel.isNotEmpty)
                          _ContentMetaChip(
                            icon: Icons.payments_outlined,
                            label: priceLabel,
                          ),
                        if (rating.isNotEmpty)
                          _ContentMetaChip(
                            icon: Icons.star_border_rounded,
                            label: rating,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ChillingzContentItem _safeChillingzContent(ChillingzContentItem item) {
  return ChillingzContentItem(
    id: _safeString(() => item.id),
    title: _safeString(() => item.title),
    description: _safeString(() => item.description),
    imagePath: _safeString(() => item.imagePath),
    priceLabel: _safeString(() => item.priceLabel),
    rating: _safeString(() => item.rating),
    status: _safeString(() => item.status),
    websiteLink: _safeString(() => item.websiteLink),
    mapLink: _safeString(() => item.mapLink),
    ticketLink: _safeString(() => item.ticketLink),
    venueName: _safeString(() => item.venueName),
    tags: _safeStringList(() => item.tags),
    socialPosts: _safeSocialPosts(() => item.socialPosts),
  );
}

List<String> _safeStringList(Object? Function() read) {
  try {
    final value = read();
    if (value is! Iterable) {
      return const <String>[];
    }
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  } catch (_) {
    return const <String>[];
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

List<ChillingzContentItem> _safeChillingzContentItems(
  Object? Function() read,
) {
  try {
    final value = read();
    if (value is List<ChillingzContentItem>) {
      return value;
    }
  } catch (_) {
    return const <ChillingzContentItem>[];
  }
  return const <ChillingzContentItem>[];
}

bool _safeBool(Object? Function() read) {
  try {
    return read() == true;
  } catch (_) {
    return false;
  }
}

class _ContentMetaChip extends StatelessWidget {
  const _ContentMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(10, min: 9, max: 11),
        vertical: context.rs(6, min: 5, max: 7),
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: context.rs(14, min: 13, max: 15),
            color: AppColors.textSecondary,
          ),
          context.rs(5, min: 4, max: 6).hSpace,
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: context.rs(11.5, min: 11, max: 12),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
