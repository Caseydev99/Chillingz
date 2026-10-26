import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_values.dart';
import 'text_styles.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    return _buildTheme(isLight: true);
  }

  static ThemeData get darkTheme {
    return _buildTheme(isLight: false);
  }

  static ThemeData _buildTheme({required bool isLight}) {
    final outlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppValues.borderRadius),
      borderSide: BorderSide.none,
    );
    final scaffoldBackground = isLight
        ? AppColors.lightBackgroundBase
        : AppColors.darkBackgroundBase;
    final inputFill = isLight
        ? AppColors.lightInputFillBase
        : AppColors.darkInputFillBase;
    final foreground = isLight ? AppColors.black : AppColors.white;
    final appBarIconColor = isLight ? AppColors.primary : AppColors.white;
    final secondaryText = isLight
        ? const Color(0x99000000)
        : const Color(0xB3FFFFFF);
    final hint = isLight ? const Color(0x80000000) : const Color(0x99FFFFFF);

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: scaffoldBackground,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _NoPageTransitionsBuilder(),
          TargetPlatform.iOS: _NoPageTransitionsBuilder(),
          TargetPlatform.macOS: _NoPageTransitionsBuilder(),
          TargetPlatform.windows: _NoPageTransitionsBuilder(),
          TargetPlatform.linux: _NoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _NoPageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme(
        brightness: isLight ? Brightness.light : Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: scaffoldBackground,
        background: scaffoldBackground,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: foreground,
        onBackground: foreground,
        onError: AppColors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.heading1.copyWith(color: foreground),
        headlineMedium: AppTextStyles.heading2.copyWith(color: foreground),
        titleMedium: AppTextStyles.title.copyWith(color: foreground),
        bodyMedium: AppTextStyles.body.copyWith(color: foreground),
        bodySmall: AppTextStyles.caption.copyWith(color: secondaryText),
        labelLarge: AppTextStyles.button,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: AppTextStyles.body.copyWith(color: hint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: outlineBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        errorBorder: outlineBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: outlineBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: AppTextStyles.button,
          minimumSize: const Size.fromHeight(AppValues.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: hint),
        fillColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return isLight ? AppColors.lightInputFillBase : AppColors.white;
        }),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: scaffoldBackground,
        foregroundColor: appBarIconColor,
        iconTheme: IconThemeData(color: appBarIconColor),
        actionsIconTheme: IconThemeData(color: appBarIconColor),
        centerTitle: true,
        titleTextStyle: AppTextStyles.title.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: isLight ? AppColors.white : const Color(0xFF241132),
        contentTextStyle: AppTextStyles.body.copyWith(
          color: isLight ? AppColors.black : AppColors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColors.primaryLight,
        closeIconColor: isLight ? AppColors.black : AppColors.white,
        insetPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: isLight ? 0.22 : 0.45),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scaffoldBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: secondaryText,
        selectedLabelStyle: AppTextStyles.body.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
        unselectedLabelStyle: AppTextStyles.caption.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          color: secondaryText,
        ),
      ),
    );
  }
}

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
