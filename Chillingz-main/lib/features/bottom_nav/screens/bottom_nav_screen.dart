import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/account_access_prompt.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../home/screens/home_screen.dart';
import '../../home/screens/saved_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../providers/bottom_nav_provider.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<BottomNavProvider>().resetToHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavProvider>(
      builder: (context, provider, child) {
        const screens = [HomeScreen(), SavedScreen(), ProfileScreen()];

        return Scaffold(
          body: screens[provider.currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: AppColors.background,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            currentIndex: provider.currentIndex,
            onTap: (index) {
              final authProvider = context.read<AuthProvider>();
              if (index != 0 && !authProvider.isSignedIn) {
                AccountAccessPrompt.show(context);
                return;
              }
              if (provider.currentIndex != index) {
                context.read<HomeProvider>().resetBrowsingFilters();
              }
              provider.updateIndex(index);
            },
            iconSize: context.rs(26, min: 24, max: 28),
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            selectedLabelStyle: TextStyle(
              fontSize: context.rs(11, min: 10, max: 12),
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: context.rs(10.5, min: 10, max: 11.5),
              fontWeight: FontWeight.w400,
            ),
            items: [
              BottomNavigationBarItem(
                icon: _BottomNavSvgIcon(
                  assetPath: AppImages.homeNav,
                  selected: provider.currentIndex == 0,
                ),
                label: AppStrings.homeTitle,
              ),
              BottomNavigationBarItem(
                icon: _BottomNavSvgIcon(
                  assetPath: AppImages.saveNav,
                  selected: provider.currentIndex == 1,
                ),
                label: AppStrings.saved,
              ),
              BottomNavigationBarItem(
                icon: _BottomNavSvgIcon(
                  assetPath: AppImages.profileNav,
                  selected: provider.currentIndex == 2,
                ),
                label: AppStrings.profileTitle,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomNavSvgIcon extends StatelessWidget {
  const _BottomNavSvgIcon({required this.assetPath, required this.selected});

  final String assetPath;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: context.rs(26, min: 24, max: 28),
      height: context.rs(26, min: 24, max: 28),
      colorFilter: ColorFilter.mode(
        selected ? AppColors.primary : AppColors.textSecondary,
        BlendMode.srcIn,
      ),
    );
  }
}
