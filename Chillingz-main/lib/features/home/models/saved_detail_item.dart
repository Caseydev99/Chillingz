import 'package:flutter/material.dart';

import 'social_post_item.dart';

class SavedDetailItem {
  const SavedDetailItem({
    required this.id,
    required this.title,
    required this.category,
    required this.imagePath,
    required this.backgroundColor,
    required this.priceLabel,
    required this.distance,
    required this.rating,
    this.feature,
    this.city,
    this.latitude,
    this.longitude,
    this.venueName = '',
    this.parentCategory = '',
    this.subcategory = '',
    this.activityType = '',
    this.websiteLink = '',
    this.mapLink = '',
    this.ticketLink = '',
    this.socialPosts = const <SocialPostItem>[],
  });

  final String id;
  final String title;
  final String category;
  final String imagePath;
  final Color backgroundColor;
  final String priceLabel;
  final String distance;
  final String rating;
  final String? feature;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String venueName;
  final String parentCategory;
  final String subcategory;
  final String activityType;
  final String websiteLink;
  final String mapLink;
  final String ticketLink;
  final List<SocialPostItem> socialPosts;
}
