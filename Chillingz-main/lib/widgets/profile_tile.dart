import 'package:flutter/material.dart';

import '../core/widgets/custom_card.dart';

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Text(title),
    );
  }
}
