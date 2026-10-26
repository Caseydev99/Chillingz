import 'package:flutter/widgets.dart';

class HomeCategoryItem {
  const HomeCategoryItem({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.icon,
    this.darkOverlay = false,
    this.routeName,
  });

  final String id;
  final String title;
  final String imagePath;
  final IconData icon;
  final bool darkOverlay;
  final String? routeName;
}
