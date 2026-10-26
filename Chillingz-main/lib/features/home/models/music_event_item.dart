import 'social_post_item.dart';

class MusicEventItem {
  const MusicEventItem({
    required this.id,
    required this.title,
    required this.location,
    required this.imagePath,
    required this.badgeText,
    required this.rating,
    required this.priceLabel,
    this.genre,
    this.feature,
    this.city,
    this.latitude,
    this.longitude,
    this.subcategory = '',
    this.headliner = '',
    this.venueName = '',
    this.timeLabel = '',
    this.websiteLink = '',
    this.mapLink = '',
    this.ticketLink = '',
    this.socialPosts = const <SocialPostItem>[],
  });

  final String id;
  final String title;
  final String location;
  final String imagePath;
  final String badgeText;
  final String rating;
  final String priceLabel;
  final String? genre;
  final String? feature;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String subcategory;
  final String headliner;
  final String venueName;
  final String timeLabel;
  final String websiteLink;
  final String mapLink;
  final String ticketLink;
  final List<SocialPostItem> socialPosts;
}
