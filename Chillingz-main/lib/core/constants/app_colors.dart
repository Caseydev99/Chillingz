import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static bool _useLightMode = false;

  static void setUseLightMode(bool value) {
    _useLightMode = value;
  }

  static bool get isLightMode => _useLightMode;

  static const Color primary = Color(0xFF7925C7);
  static const Color primaryLight = Color(0xFF8E42D8);
  static const Color darkBackgroundBase = Color(0xFF2D0D47);
  static const Color lightBackgroundBase = Color(0xFFFCFAFF);
  static const Color darkInputFillBase = Color(0xFF4A1574);
  static const Color lightInputFillBase = Color(0xFFFFFFFF);
  static const Color darkSettingsCardBase = Color(0xFF27263C);
  static const Color lightSettingsCardBase = Color(0xFFFFFFFF);
  static const Color darkSettingsTileBackground = Color(0xFF4A1574);
  static const Color lightSettingsTileBackground = Color(0xFFFFFFFF);
  static const Color darkMoodChipBackground = Color(0xFF4A1574);
  static const Color lightMoodChipBackground = Color(0xFFF0E5FA);
  static const Color black = Color(0xFF111111);
  static const Color white = Color(0xFFFFFFFF);
  static Color get authBackground => background;
  static Color get authTextPrimary => textPrimary;
  static Color get authTextSecondary => textSecondary;
  static Color get background =>
      _useLightMode ? lightBackgroundBase : darkBackgroundBase;
  static Color get textPrimary => _useLightMode ? black : white;
  static Color get textSecondary =>
      _useLightMode ? const Color(0xCC111111) : const Color(0xCCFFFFFF);
  static Color get textMuted =>
      _useLightMode ? const Color(0xB3111111) : const Color(0xB3FFFFFF);
  static Color get border =>
      _useLightMode ? const Color(0xFFE3D8EF) : const Color(0x33FFFFFF);
  static Color get inputFill =>
      _useLightMode ? lightInputFillBase : darkInputFillBase;
  static Color get hint =>
      _useLightMode ? const Color(0x80000000) : const Color(0x99FFFFFF);
  static const Color error = Color(0xFFD92D20);
  static Color get settingsCardBase =>
      _useLightMode ? lightSettingsCardBase : darkSettingsCardBase;
  static Color get settingsTileBackground =>
      _useLightMode ? lightSettingsTileBackground : darkSettingsTileBackground;
  static Color get moodChipBackground =>
      _useLightMode ? lightMoodChipBackground : darkMoodChipBackground;
  static const Color moodChipSelectedBackground = Color(0xFFEFD8FF);

  static LinearGradient get settingsProfileGradient => LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [settingsCardBase, settingsCardBase],
  );

  static LinearGradient get settingsProfileOverlayGradient => LinearGradient(
    begin: const Alignment(-1.0, -0.2),
    end: const Alignment(1.0, 0.5),
    colors: _useLightMode
        ? const [Color(0x99F661F8), Color(0x9979E8EC)]
        : const [Color(0xB3F661F8), Color(0xB379E8EC)],
  );

  static const LinearGradient moodChipSelectedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFC36AE6), Color(0xFF8FB3D7)],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF9F3AF2), Color(0xFF7925C7)],
  );

  static const Color musicGenreBaseOverlay = Color(0x1AEBEBEB);
  static Color get musicEventCardBackground =>
      _useLightMode ? const Color(0xFFFFFFFF) : const Color(0x3308FFF9);
  static Color get activitiesCardBackground =>
      _useLightMode ? const Color(0xFFFFFFFF) : const Color(0x33FF00E6);
  static Color get foodCardBackground =>
      _useLightMode ? const Color(0xFFFFFFFF) : const Color(0x33FF0004);
  static Color get eventCardBackground =>
      _useLightMode ? const Color(0xFFFFFFFF) : const Color(0x33FDC700);
  static Color get healthCardBackground =>
      _useLightMode ? const Color(0xFFFFFFFF) : const Color(0x3300FF1E);
  static Color get networkingCardBackground =>
      _useLightMode ? const Color(0xFFFFFFFF) : const Color(0x33005EFF);

  static const LinearGradient musicGenreBottomOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x99000000)],
    stops: [0.7024, 0.8819],
  );

  static const LinearGradient musicGenreTopOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x99000000), Color(0x00000000)],
    stops: [0.0, 0.6169],
  );
}
