import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../features/auth/models/interest_option.dart';
import 'empty_state.dart';
import 'interest_chip.dart';

class OnboardingInterestWrap extends StatelessWidget {
  const OnboardingInterestWrap({
    super.key,
    required this.items,
    required this.isSelected,
    required this.onTap,
  });

  final List<InterestOption> items;
  final bool Function(String id) isSelected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        message: AppStrings.currentlyUnavailable,
        icon: Icons.local_offer_outlined,
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: items.map((item) {
        return InterestChip(
          label: item.label,
          isSelected: isSelected(item.id),
          onTap: () => onTap(item.id),
        );
      }).toList(),
    );
  }
}
