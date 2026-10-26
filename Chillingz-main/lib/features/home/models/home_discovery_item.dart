import 'chillingz_content_item.dart';

class HomeDiscoveryItem {
  const HomeDiscoveryItem({
    required this.id,
    required this.title,
    required this.imagePath,
    this.tag = '',
    this.tags = const <String>[],
    this.isNature = false,
    this.contentItems = const <ChillingzContentItem>[],
  });

  final String id;
  final String title;
  final String imagePath;
  final String tag;
  final List<String> tags;
  final bool isNature;
  final List<ChillingzContentItem> contentItems;
}
