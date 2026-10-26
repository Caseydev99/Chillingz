import 'package:flutter/material.dart';

import 'app_logo.dart';

class SavedTopBar extends StatelessWidget {
  const SavedTopBar({
    super.key,
    this.logoHeight = 94,
  });

  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return Center(child: AppLogo(height: logoHeight));
  }
}
