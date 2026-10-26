import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/navigation/app_navigator.dart';
import 'core/services/location_permission_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/bottom_nav/providers/bottom_nav_provider.dart';
import 'features/home/providers/home_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'routes/app_routes.dart';

class ChillingzApp extends StatelessWidget {
  const ChillingzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<HomeProvider>(create: (_) => HomeProvider()),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(),
        ),
        ChangeNotifierProvider<BottomNavProvider>(
          create: (_) => BottomNavProvider(),
        ),
        ChangeNotifierProvider<LocationPermissionController>.value(
          value: LocationPermissionController.instance,
        ),
      ],
      // Rebuild the app shell only when the theme changes. Listening to the
      // entire profile provider here made unrelated actions (such as choosing
      // a mood) rebuild MaterialApp, navigation and network avatars.
      child: Selector<ProfileProvider, ThemeMode>(
        selector: (context, profileProvider) => profileProvider.themeMode,
        builder: (context, themeMode, child) {
          final platformBrightness =
              WidgetsBinding.instance.platformDispatcher.platformBrightness;
          final useLightMode =
              themeMode == ThemeMode.light ||
              (themeMode == ThemeMode.system &&
                  platformBrightness == Brightness.light);
          final overlayStyle = SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: useLightMode
                ? AppColors.lightBackgroundBase
                : AppColors.darkBackgroundBase,
            systemNavigationBarDividerColor: Colors.transparent,
            statusBarIconBrightness: useLightMode
                ? Brightness.dark
                : Brightness.light,
            systemNavigationBarIconBrightness: useLightMode
                ? Brightness.dark
                : Brightness.light,
            statusBarBrightness: useLightMode
                ? Brightness.light
                : Brightness.dark,
          );

          AppColors.setUseLightMode(useLightMode);
          SystemChrome.setSystemUIOverlayStyle(overlayStyle);

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlayStyle,
            child: MaterialApp(
              title: 'Chillingz',
              debugShowCheckedModeBanner: false,
              navigatorKey: appNavigatorKey,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              initialRoute: AppRoutes.splash,
              onGenerateRoute: AppRoutes.onGenerateRoute,
              builder: kIsWeb ? _webPhoneFrame : null,
            ),
          );
        },
      ),
    );
  }
}

/// The app is designed for portrait phones; on wide browser windows keep it
/// at phone width, centred, rather than stretching every screen edge to edge.
Widget _webPhoneFrame(BuildContext context, Widget? child) {
  const maxWidth = 480.0;
  final mediaQuery = MediaQuery.of(context);
  if (mediaQuery.size.width <= maxWidth) {
    return child ?? const SizedBox.shrink();
  }

  return ColoredBox(
    color: Colors.black,
    child: Center(
      child: SizedBox(
        width: maxWidth,
        child: MediaQuery(
          data: mediaQuery.copyWith(
            size: Size(maxWidth, mediaQuery.size.height),
          ),
          child: ClipRect(child: child),
        ),
      ),
    ),
  );
}
