import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
  });

  final String title;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: showBackButton ? 68 : null,
      leading: showBackButton
          ? IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.chevron_left_rounded),
              iconSize: 46,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
            )
          : null,
      title: Text(title),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
