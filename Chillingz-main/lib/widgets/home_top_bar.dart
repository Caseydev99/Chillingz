import 'package:flutter/material.dart';

import 'app_logo.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: AppLogo(height: 94));
  }
}
