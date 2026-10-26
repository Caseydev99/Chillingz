class SocialPostItem {
  const SocialPostItem({
    required this.id,
    required this.username,
    required this.platform,
    required this.platformIconPath,
    required this.avatarImagePath,
    required this.imagePath,
    required this.caption,
    required this.tags,
    this.showPlayIcon = false,
  });

  final String id;
  final String username;
  final String platform;
  final String platformIconPath;
  final String avatarImagePath;
  final String imagePath;
  final String caption;
  final String tags;
  final bool showPlayIcon;
}
