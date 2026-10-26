import 'social_post_item.dart';

class ChillingzContentItem {
  const ChillingzContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    this.priceLabel = '',
    this.rating = '',
    this.status = '',
    this.websiteLink = '',
    this.mapLink = '',
    this.ticketLink = '',
    this.venueName = '',
    this.tags = const <String>[],
    this.socialPosts = const <SocialPostItem>[],
  });

  final String id;
  final String title;
  final String description;
  final String imagePath;
  final String priceLabel;
  final String rating;
  final String status;
  final String? websiteLink;
  final String? mapLink;
  final String? ticketLink;
  final String? venueName;
  final List<String>? tags;
  final List<SocialPostItem>? socialPosts;
}
