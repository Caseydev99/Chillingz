import 'package:flutter/material.dart';

import '../core/widgets/custom_card.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
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
