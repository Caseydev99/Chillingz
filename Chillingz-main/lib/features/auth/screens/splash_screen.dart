import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/services/location_permission_controller.dart';
import '../../../core/utils/extensions.dart';
import '../../../routes/app_routes.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.84,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _controller.forward();
    _goToNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goToNextScreen() async {
    final locationController = LocationPermissionController.instance;
    final sessionFuture = context.read<AuthProvider>().restoreSession();
    final locationFuture = locationController.refresh(enforce: false);
    final skipPreferenceFuture = locationController.ensureSkipPreferenceLoaded();

    await Future<void>.delayed(AppValues.splashDuration);

    final isSignedIn = await sessionFuture;
    final hasLocationAccess = await locationFuture;
    await skipPreferenceFuture;

    if (!mounted) {
      return;
    }

    final nextRoute = isSignedIn ? AppRoutes.bottomNav : AppRoutes.signUp;

    if (!hasLocationAccess && locationController.canRequestPermission) {
      // The gate enables enforcement itself once access is granted.
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.locationPermission,
        arguments: nextRoute,
      );
      return;
    }

    if (hasLocationAccess) {
      locationController.enableEnforcement();
    } else {
      locationController.disableEnforcement();
    }
    Navigator.pushReplacementNamed(context, nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackgroundBase,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(color: AppColors.darkBackgroundBase),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _SplashLogo(
                    controller: _controller,
                    logoSize: (context.screenWidth * 0.5)
                        .clamp(AppValues.splashLogoSize, 220.0)
                        .toDouble(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({
    required this.controller,
    required this.logoSize,
  });

  final AnimationController controller;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: logoSize + 54,
          height: logoSize + 54,
          alignment: Alignment.center,
          child: Image.asset(
            AppImages.appLogo,
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                AppImages.legacyAppLogo,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'C',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
