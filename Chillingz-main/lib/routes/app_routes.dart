import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/services/activity_tracking_service.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/location_permission_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/bottom_nav/screens/bottom_nav_screen.dart';
import '../features/home/models/food_cuisine_item.dart';
import '../features/home/models/music_event_item.dart';
import '../features/home/models/music_genre_item.dart';
import '../features/home/models/saved_detail_item.dart';
import '../features/home/screens/activities_screen.dart';
import '../features/home/screens/activity_detail_screen.dart';
import '../features/home/screens/event_detail_screen.dart';
import '../features/home/screens/events_screen.dart';
import '../features/home/screens/food_cuisine_detail_screen.dart';
import '../features/home/screens/food_drink_screen.dart';
import '../features/home/screens/food_place_detail_screen.dart';
import '../features/home/screens/health_detail_screen.dart';
import '../features/home/screens/health_wellbeing_screen.dart';
import '../features/home/screens/music_event_detail_screen.dart';
import '../features/home/screens/music_genre_detail_screen.dart';
import '../features/home/screens/music_screen.dart';
import '../features/home/screens/networking_detail_screen.dart';
import '../features/home/screens/networking_screen.dart';
import '../features/home/screens/saved_detail_subcategory_screen.dart';
import '../features/profile/models/notification_item.dart';
import '../features/profile/screens/appearance_screen.dart';
import '../features/profile/screens/change_password_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/interests_selection_screen.dart';
import '../features/profile/screens/mood_selection_screen.dart';
import '../features/profile/screens/notification_detail_screen.dart';
import '../features/profile/screens/notifications_screen.dart';
import '../features/profile/screens/privacy_policy_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/profile/screens/terms_conditions_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String locationPermission = '/location-permission';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String bottomNav = '/bottom-nav';
  static const String music = '/music';
  static const String musicGenreDetail = '/music-genre-detail';
  static const String musicEventDetail = '/music-event-detail';
  static const String activities = '/activities';
  static const String activityDetail = '/activity-detail';
  static const String savedDetailSubcategory = '/saved-detail-subcategory';
  static const String events = '/events';
  static const String eventDetail = '/event-detail';
  static const String foodDrink = '/food-drink';
  static const String foodCuisineDetail = '/food-cuisine-detail';
  static const String foodPlaceDetail = '/food-place-detail';
  static const String healthWellbeing = '/health-wellbeing';
  static const String healthDetail = '/health-detail';
  static const String networking = '/networking';
  static const String networkingDetail = '/networking-detail';
  static const String changePassword = '/change-password';
  static const String editProfile = '/edit-profile';
  static const String appearance = '/appearance';
  static const String interestsSelection = '/interests-selection';
  static const String moodSelectionScreen = '/mood-selection';
  static const String notifications = '/notifications';
  static const String notificationDetail = '/notification-detail';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsConditions = '/terms-conditions';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute<void>(builder: (_) => const SplashScreen());
      case AppRoutes.locationPermission:
        final nextRoute = settings.arguments as String?;
        return MaterialPageRoute<bool>(
          builder: (_) => LocationPermissionScreen(nextRoute: nextRoute),
        );
      case AppRoutes.onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingScreen(),
        );
      case AppRoutes.login:
        return MaterialPageRoute<void>(builder: (_) => const LoginScreen());
      case AppRoutes.signUp:
        return MaterialPageRoute<void>(builder: (_) => const SignupScreen());
      case AppRoutes.forgotPassword:
        final initialEmail = settings.arguments as String? ?? '';
        return MaterialPageRoute<void>(
          builder: (_) => ForgotPasswordScreen(initialEmail: initialEmail),
        );
      case AppRoutes.resetPassword:
        return MaterialPageRoute<void>(
          builder: (_) => const ResetPasswordScreen(),
        );
      case AppRoutes.bottomNav:
        return MaterialPageRoute<void>(builder: (_) => const BottomNavScreen());
      case AppRoutes.music:
        _trackCategoryView(AppStrings.music);
        return CupertinoPageRoute<void>(builder: (_) => const MusicScreen());
      case AppRoutes.musicGenreDetail:
        final item = settings.arguments as MusicGenreItem;
        _trackCategoryView(AppStrings.music, item: item.title);
        return CupertinoPageRoute<void>(
          builder: (_) => MusicGenreDetailScreen(genre: item),
        );
      case AppRoutes.musicEventDetail:
        final item = settings.arguments as MusicEventItem;
        _trackListingView(AppStrings.music, item: item.title, city: item.city);
        return CupertinoPageRoute<void>(
          builder: (_) => MusicEventDetailScreen(item: item),
        );
      case AppRoutes.activities:
        _trackCategoryView(AppStrings.activities);
        return CupertinoPageRoute<void>(
          builder: (_) => const ActivitiesScreen(),
        );
      case AppRoutes.activityDetail:
        final item = settings.arguments as SavedDetailItem;
        _trackListingView(
          AppStrings.activities,
          item: item.title,
          city: item.city,
        );
        return CupertinoPageRoute<void>(
          builder: (_) => ActivityDetailScreen(item: item),
        );
      case AppRoutes.savedDetailSubcategory:
        final args = settings.arguments as SavedDetailSubcategoryArgs;
        _trackCategoryView(
          _subcategoryCategoryName(args.kind),
          item: args.item.title,
        );
        return CupertinoPageRoute<void>(
          builder: (_) => SavedDetailSubcategoryScreen(args: args),
        );
      case AppRoutes.events:
        _trackCategoryView(AppStrings.events);
        return CupertinoPageRoute<void>(builder: (_) => const EventsScreen());
      case AppRoutes.eventDetail:
        final item = settings.arguments as MusicEventItem;
        _trackListingView(AppStrings.events, item: item.title, city: item.city);
        return CupertinoPageRoute<void>(
          builder: (_) => EventDetailScreen(item: item),
        );
      case AppRoutes.foodDrink:
        _trackCategoryView(AppStrings.foodDrink);
        return CupertinoPageRoute<void>(
          builder: (_) => const FoodDrinkScreen(),
        );
      case AppRoutes.foodCuisineDetail:
        final item = settings.arguments as FoodCuisineItem;
        _trackCategoryView(AppStrings.foodDrink, item: item.title);
        return CupertinoPageRoute<void>(
          builder: (_) => FoodCuisineDetailScreen(item: item),
        );
      case AppRoutes.foodPlaceDetail:
        final item = settings.arguments as SavedDetailItem;
        _trackListingView(
          AppStrings.foodDrink,
          item: item.title,
          city: item.city,
        );
        return CupertinoPageRoute<void>(
          builder: (_) => FoodPlaceDetailScreen(item: item),
        );
      case AppRoutes.healthWellbeing:
        _trackCategoryView(AppStrings.healthWellbeing);
        return CupertinoPageRoute<void>(
          builder: (_) => const HealthWellbeingScreen(),
        );
      case AppRoutes.healthDetail:
        final item = settings.arguments as SavedDetailItem;
        _trackListingView(
          AppStrings.healthWellbeing,
          item: item.title,
          city: item.city,
        );
        return CupertinoPageRoute<void>(
          builder: (_) => HealthDetailScreen(item: item),
        );
      case AppRoutes.networking:
        _trackCategoryView(AppStrings.networking);
        return CupertinoPageRoute<void>(
          builder: (_) => const NetworkingScreen(),
        );
      case AppRoutes.networkingDetail:
        final item = settings.arguments as SavedDetailItem;
        _trackListingView(
          AppStrings.networking,
          item: item.title,
          city: item.city,
        );
        return CupertinoPageRoute<void>(
          builder: (_) => NetworkingDetailScreen(item: item),
        );
      case AppRoutes.changePassword:
        return MaterialPageRoute<void>(
          builder: (_) => const ChangePasswordScreen(),
        );
      case AppRoutes.editProfile:
        return MaterialPageRoute<void>(
          builder: (_) => const EditProfileScreen(),
        );
      case AppRoutes.appearance:
        return MaterialPageRoute<void>(
          builder: (_) => const AppearanceScreen(),
        );
      case AppRoutes.interestsSelection:
        return MaterialPageRoute<void>(
          builder: (_) => const InterestsSelectionScreen(),
        );
      case AppRoutes.moodSelectionScreen:
        return MaterialPageRoute<void>(
          builder: (_) => const MoodSelectionScreen(),
        );
      case AppRoutes.notifications:
        return MaterialPageRoute<void>(
          builder: (_) => const NotificationsScreen(),
        );
      case AppRoutes.notificationDetail:
        final item = settings.arguments as NotificationItem;
        return MaterialPageRoute<void>(
          builder: (_) => NotificationDetailScreen(item: item),
        );
      case AppRoutes.privacyPolicy:
        return MaterialPageRoute<void>(
          builder: (_) => const PrivacyPolicyScreen(),
        );
      case AppRoutes.termsConditions:
        return MaterialPageRoute<void>(
          builder: (_) => const TermsConditionsScreen(),
        );
      case AppRoutes.settings:
        return MaterialPageRoute<void>(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute<void>(builder: (_) => const SplashScreen());
    }
  }

  /// Every category and listing screen is opened through [onGenerateRoute], so
  /// the view events are recorded here rather than in each screen.
  static void _trackCategoryView(String category, {String? item}) {
    ActivityTrackingService.instance.trackActivityInBackground(
      action: ActivityActions.categoryView,
      category: category,
      item: item,
    );
  }

  static void _trackListingView(
    String category, {
    required String item,
    String? city,
  }) {
    ActivityTrackingService.instance.trackActivityInBackground(
      action: ActivityActions.listingView,
      category: category,
      item: item,
      city: city,
    );
  }

  static String _subcategoryCategoryName(SavedDetailSubcategoryKind kind) {
    switch (kind) {
      case SavedDetailSubcategoryKind.activities:
        return AppStrings.activities;
      case SavedDetailSubcategoryKind.health:
        return AppStrings.healthWellbeing;
      case SavedDetailSubcategoryKind.networking:
        return AppStrings.networking;
    }
  }
}
