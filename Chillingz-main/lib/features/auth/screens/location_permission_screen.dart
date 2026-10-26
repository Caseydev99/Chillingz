import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/services/location_permission_controller.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/custom_button.dart';

/// Full screen explanation shown immediately before the system location
/// prompt.
///
/// App Review guideline 5.1.1(v) requires that a pre-permission message always
/// leads into the system request, so this screen offers no way to dismiss the
/// prompt: the single action asks the OS for permission and then continues to
/// [nextRoute] (or pops) whatever the user answers. Declining is handled in the
/// system dialog, and the app stays fully usable without location.
///
/// The status itself comes from [LocationPermissionController], so a change
/// made in the OS settings is reflected here without any extra polling.
class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key, this.nextRoute});

  final String? nextRoute;

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  final LocationPermissionController _controller =
      LocationPermissionController.instance;

  bool _isBusy = false;
  bool _isNavigating = false;
  bool _didInteract = false;
  int _deniedAttempts = 0;
  String? _errorMessage;

  /// Asking again is pointless once the permission is permanently denied, and
  /// iOS also stops showing the system dialog after the first refusal.
  bool get _isBlocked =>
      _controller.isPermanentlyDenied || _deniedAttempts >= 2;

  @override
  void initState() {
    super.initState();
    _controller.setGateVisible(true);
    _controller.addListener(_handleStatusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluate();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleStatusChanged);
    _controller.setGateVisible(false);
    super.dispose();
  }

  /// Reacts to a status change coming from anywhere in the app, e.g. the user
  /// granting access in the OS settings and returning to Chillingz.
  void _handleStatusChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = _currentMessage();
    });

    if (_controller.hasLocationAccess) {
      _goToNextScreen();
    }
  }

  Future<void> _evaluate({bool requestPermission = false}) async {
    if (_isBusy || _isNavigating || !mounted) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    final hasAccess = await _controller.refresh(
      requestPermission: requestPermission,
      enforce: false,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isBusy = false;
      if (hasAccess) {
        _deniedAttempts = 0;
      } else if (requestPermission) {
        _didInteract = true;
        _deniedAttempts++;
      }
      _errorMessage = _currentMessage();
    });

    if (hasAccess) {
      _goToNextScreen();
    }
  }

  String? _currentMessage() {
    if (_controller.isPermissionGranted) {
      return _controller.serviceEnabled
          ? null
          : AppStrings.locationServiceDisabledMessage;
    }

    if (_isBlocked) {
      return AppStrings.locationPermissionBlockedMessage;
    }

    if (!_controller.serviceEnabled) {
      return AppStrings.locationServiceDisabledMessage;
    }

    return _didInteract ? AppStrings.locationPermissionDeniedMessage : null;
  }

  Future<void> _handlePrimaryAction() async {
    if (_isBusy || _isNavigating) {
      return;
    }

    setState(() => _isBusy = true);
    await _controller.refresh(requestPermission: true, enforce: false);
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    _goToNextScreen();
  }

  void _goToNextScreen() {
    if (_isNavigating || !mounted) {
      return;
    }

    _isNavigating = true;
    if (_controller.hasLocationAccess) {
      _controller.enableEnforcement();
    } else {
      _controller.disableEnforcement();
    }

    final nextRoute = widget.nextRoute;
    if (nextRoute != null) {
      Navigator.pushReplacementNamed(context, nextRoute);
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = context.isSmallPhone ? 96.0 : 112.0;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.authBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppValues.screenHorizontalPadding,
            ),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7925C7),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    AppImages.locationPreferenceIcon,
                    width: iconSize * 0.46,
                    height: iconSize * 0.46,
                    colorFilter: const ColorFilter.mode(
                      AppColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                32.vSpace,
                Text(
                  AppStrings.enableLocation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                14.vSpace,
                Text(
                  _errorMessage ?? AppStrings.enableLocationSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: _errorMessage == null
                        ? AppColors.authTextSecondary
                        : AppColors.error,
                  ),
                ),
                8.vSpace,
                Text(
                  AppStrings.locationOptionalNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    color: AppColors.authTextSecondary,
                  ),
                ),
                const Spacer(),
                CustomButton(
                  label: AppStrings.continueLabel,
                  isLoading: _isBusy,
                  onPressed: _isBusy ? null : _handlePrimaryAction,
                ),
                16.vSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
