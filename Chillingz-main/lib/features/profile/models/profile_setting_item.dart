class ProfileSettingItem {
  const ProfileSettingItem({
    required this.title,
    required this.iconPath,
    this.routeName,
    this.hasToggle = false,
  });

  final String title;
  final String iconPath;
  final String? routeName;
  final bool hasToggle;
}
