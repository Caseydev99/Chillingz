import 'package:flutter/material.dart';

import '../core/utils/extensions.dart';
import 'saved_search_bar.dart';
import 'saved_top_bar.dart';

class SavedHeaderSection extends StatelessWidget {
  const SavedHeaderSection({
    super.key,
    this.controller,
    this.onChanged,
    this.onFilterTap,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SavedTopBar(logoHeight: 94),
        context.rs(2, min: 1, max: 4).vSpace,
        SavedSearchBar(
          height: 52,
          iconSize: 26,
          filterButtonSize: 40,
          filterIconSize: 18,
          borderRadius: 26,
          leftPadding: 16,
          rightPadding: 10,
          controller: controller,
          onChanged: onChanged,
          onFilterTap: onFilterTap,
        ),
      ],
    );
  }
}
