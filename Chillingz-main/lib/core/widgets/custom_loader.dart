import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CustomLoader extends StatelessWidget {
  const CustomLoader({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppColors.primary,
      ),
    );
  }
}
