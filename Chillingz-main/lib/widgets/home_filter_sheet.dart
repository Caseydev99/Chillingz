import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/extensions.dart';
import 'music_filter_chip.dart';

class HomeFilterSheet extends StatefulWidget {
  const HomeFilterSheet({
    super.key,
    required this.title,
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
    required this.onReset,
  });

  final String title;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;
  final VoidCallback onReset;

  @override
  State<HomeFilterSheet> createState() => _HomeFilterSheetState();
}

class _HomeFilterSheetState extends State<HomeFilterSheet> {
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: context.rs(6, min: 4, max: 8)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.rs(18, min: 16, max: 20),
            context.rs(14, min: 12, max: 16),
            context.rs(18, min: 16, max: 20),
            context.rs(14, min: 12, max: 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: context.rs(52, min: 48, max: 56),
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              context.rs(16, min: 14, max: 18).vSpace,
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: context.rs(18, min: 17, max: 19),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.onReset();
                      setState(() {
                        _selectedFilter = AppStrings.all;
                      });
                    },
                    child: Text(
                      AppStrings.reset,
                      style: TextStyle(
                        fontSize: context.rs(12, min: 11.5, max: 13),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              context.rs(14, min: 12, max: 16).vSpace,
              Wrap(
                spacing: context.rs(8, min: 8, max: 10),
                runSpacing: context.rs(8, min: 8, max: 10),
                children: widget.filters.map((filter) {
                  return GestureDetector(
                    onTap: () {
                      widget.onSelected(filter);
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: MusicFilterChip(
                      label: filter,
                      isSelected: _selectedFilter == filter,
                      selectedBackgroundColor: AppColors.primary,
                      selectedBorderColor: AppColors.primary,
                      selectedTextColor: AppColors.white,
                      unselectedBackgroundColor: AppColors.background,
                      unselectedBorderColor: const Color(0xFF8A44D8),
                      unselectedTextColor: AppColors.textPrimary,
                      horizontalPadding: context.rs(15, min: 14, max: 16),
                      verticalPadding: context.rs(8, min: 7, max: 8),
                      fontSize: context.rs(11.8, min: 11.3, max: 12),
                      borderWidth: 1,
                    ),
                  );
                }).toList(),
              ),
              context.rs(18, min: 16, max: 20).vSpace,
            ],
          ),
        ),
      ),
    );
  }
}
