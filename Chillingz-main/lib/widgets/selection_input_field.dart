import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';

class SelectionInputField extends StatelessWidget {
  const SelectionInputField({
    super.key,
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.rs(36, min: 34, max: 40),
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(10, min: 10, max: 12),
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(
          context.rs(10, min: 10, max: 12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: context.rs(14, min: 13, max: 16),
            color: AppColors.hint,
          ),
          context.rs(8, min: 8, max: 10).hSpace,
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.rs(11, min: 10.5, max: 12),
                fontWeight: FontWeight.w400,
                color: AppColors.hint,
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: context.rs(18, min: 17, max: 20),
            color: AppColors.hint,
          ),
        ],
      ),
    );
  }
}
