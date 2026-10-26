import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/extensions.dart';
import '../features/home/providers/home_provider.dart';

class HomeSearchSheet extends StatefulWidget {
  const HomeSearchSheet({super.key});

  @override
  State<HomeSearchSheet> createState() => _HomeSearchSheetState();
}

class _HomeSearchSheetState extends State<HomeSearchSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<HomeProvider>().homeSearchQuery,
    );
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Material(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              minimum: EdgeInsets.only(bottom: context.rs(6, min: 4, max: 8)),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.rs(18, min: 16, max: 20),
                  context.rs(10, min: 10, max: 12),
                  context.rs(18, min: 16, max: 20),
                  context.rs(14, min: 12, max: 16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: context.rs(54, min: 50, max: 58),
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    context.rs(16, min: 14, max: 18).vSpace,
                    Text(
                      AppStrings.searchHome,
                      style: TextStyle(
                        fontSize: context.rs(16, min: 15, max: 17),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    context.rs(10, min: 9, max: 12).vSpace,
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: provider.updateHomeSearchQuery,
                      style: TextStyle(
                        fontSize: context.rs(14, min: 13, max: 15),
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: AppStrings.homeSearchHint,
                        hintStyle: TextStyle(
                          fontSize: context.rs(12.5, min: 12, max: 13),
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: context.rs(22, min: 20, max: 24),
                        ),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _controller.clear();
                                  provider.updateHomeSearchQuery('');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: context.rs(12, min: 10, max: 14),
                          vertical: context.rs(14, min: 13, max: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
