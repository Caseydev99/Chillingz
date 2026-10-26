import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Action names recorded in `userActivity.action`.
///
/// The admin panel reads action names straight from the stored data, so these
/// values are the contract for the analytics screens.
abstract final class ActivityActions {
  static const String login = 'login';
  static const String appOpen = 'app_open';
  static const String categoryView = 'category_view';
  static const String listingView = 'listing_view';
  static const String search = 'search';
  static const String itemSaved = 'item_saved';
  static const String itemUnsaved = 'item_unsaved';
}

/// Values written to `userActivity.platform`.
abstract final class ActivityPlatforms {
  static const String ios = 'ios';
  static const String android = 'android';
}

/// Writes user activity events to the `userActivity` Firestore collection.
///
/// Every event carries the operating system that produced it in a top-level
/// `platform` field so the admin panel can filter activity by iOS or Android.
/// The platform is resolved when the event is created rather than when it
/// reaches Firestore, so an event queued offline keeps the platform of the
/// device that produced it.
class ActivityTrackingService {
  ActivityTrackingService._();

  static final ActivityTrackingService instance = ActivityTrackingService._();

  static const String collectionPath = 'userActivity';

  /// Resolved lazily so importing this file never touches Firebase.
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// The operating system of the device running the app.
  static String get currentPlatform =>
      platformFor(isWeb: kIsWeb, targetPlatform: defaultTargetPlatform);

  /// Maps a Flutter target platform onto the stored `platform` value.
  ///
  /// iOS and Android are the shipping targets and the two values the admin
  /// filter offers. Other targets record their own name instead of an iOS or
  /// Android value that would misreport where the event came from.
  static String platformFor({
    required bool isWeb,
    required TargetPlatform targetPlatform,
  }) {
    if (isWeb) {
      return 'web';
    }

    switch (targetPlatform) {
      case TargetPlatform.iOS:
        return ActivityPlatforms.ios;
      case TargetPlatform.android:
        return ActivityPlatforms.android;
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  /// Builds the document stored for a single activity event.
  ///
  /// Optional details are omitted when blank so the admin shows a missing
  /// value rather than an empty string.
  static Map<String, Object?> buildRecord({
    required String userId,
    required String action,
    required String platform,
    required DateTime timestamp,
    String? userName,
    String? item,
    String? category,
    String? city,
  }) {
    return <String, Object?>{
      'userId': userId,
      if (_hasText(userName)) 'user': userName!.trim(),
      'action': action,
      if (_hasText(item)) 'item': item!.trim(),
      if (_hasText(category)) 'category': category!.trim(),
      if (_hasText(city)) 'city': city!.trim(),
      'platform': platform,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }

  /// Records one activity event for the signed in user.
  ///
  /// Never throws: tracking is best effort and must not interrupt the flow
  /// that triggered it, so a missing Firebase app or a rejected write is
  /// swallowed rather than surfaced to the user.
  Future<void> trackActivity({
    required String action,
    String? item,
    String? category,
    String? city,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        // Firestore rules only accept an activity document whose `userId`
        // matches the caller, so guest browsing records nothing.
        return;
      }

      final record = buildRecord(
        userId: user.uid,
        action: action,
        platform: currentPlatform,
        timestamp: DateTime.now(),
        userName: user.displayName,
        item: item,
        category: category,
        city: city,
      );

      // Offline writes are queued by the Firestore SDK and keep the platform
      // resolved above, so a queued event is never relabelled on upload.
      await _firestore.collection(collectionPath).add(record);
    } catch (_) {
      // Tracking failures must not break the flow that produced the event.
    }
  }

  /// Fire-and-forget variant for call sites that cannot await, such as route
  /// generation.
  void trackActivityInBackground({
    required String action,
    String? item,
    String? category,
    String? city,
  }) {
    unawaited(
      trackActivity(action: action, item: item, category: category, city: city),
    );
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
