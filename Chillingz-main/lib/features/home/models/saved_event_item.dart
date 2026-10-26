class SavedEventItem {
  const SavedEventItem({
    required this.id,
    required this.title,
    required this.location,
    required this.imagePath,
    required this.badgeText,
    required this.priceLabel,
  });

  final String id;
  final String title;
  final String location;
  final String imagePath;
  final String badgeText;
  final String priceLabel;
}
