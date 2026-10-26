import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_images.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/extensions.dart';
import '../core/services/location_permission_controller.dart';
import '../core/utils/account_access_prompt.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/home/providers/home_provider.dart';
import '../features/profile/providers/profile_provider.dart';
import '../routes/app_routes.dart';

class LocationBar extends StatelessWidget {
  const LocationBar({super.key});

  /// Re-reads the device location. When access is missing it sends the user to
  /// the permission screen first, so tapping never silently does nothing.
  Future<void> _refreshLocation(BuildContext context) async {
    final provider = context.read<HomeProvider>();
    if (provider.isUpdatingLocation) {
      return;
    }

    final hasAccess = await LocationPermissionController.instance.refresh(
      enforce: false,
    );

    if (!context.mounted) {
      return;
    }

    if (!hasAccess) {
      await Navigator.pushNamed(context, AppRoutes.locationPermission);
      if (!context.mounted ||
          !LocationPermissionController.instance.hasLocationAccess) {
        return;
      }
    }

    await provider.enableLocation();
  }

  @override
  Widget build(BuildContext context) {
    final locationLabel = context.select<HomeProvider, String>(
      (provider) => provider.locationLabel,
    );
    final hasUnreadNotifications = context.select<ProfileProvider, bool>(
      (provider) => provider.hasUnreadNotifications,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.isLightMode
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _refreshLocation(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppStrings.currentLocation,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.isLightMode
                              ? AppColors.primary
                              : AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  5.vSpace,
                  Row(
                    children: [
                      Image.asset(
                        AppImages.mapLogo,
                        width: 14,
                        height: 14,
                        fit: BoxFit.contain,
                      ),
                      6.hSpace,
                      Expanded(
                        child: Text(
                          locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          12.hSpace,
          GestureDetector(
            onTap: () {
              if (!context.read<AuthProvider>().isSignedIn) {
                AccountAccessPrompt.show(context);
                return;
              }
              Navigator.pushNamed(context, AppRoutes.notifications);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7925C7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AppImages.bellIcon,
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        AppColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                if (hasUnreadNotifications)
                  Positioned(
                    top: 1,
                    right: 1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.inputFill,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
