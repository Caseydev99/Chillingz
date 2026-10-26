import 'package:chillingz/core/services/activity_tracking_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('platform detection', () {
    test('an iPhone or iPad records ios', () {
      expect(
        ActivityTrackingService.platformFor(
          isWeb: false,
          targetPlatform: TargetPlatform.iOS,
        ),
        'ios',
      );
    });

    test('an Android phone or tablet records android', () {
      expect(
        ActivityTrackingService.platformFor(
          isWeb: false,
          targetPlatform: TargetPlatform.android,
        ),
        'android',
      );
    });

    test('a non-mobile target never reports itself as ios or android', () {
      for (final targetPlatform in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        final platform = ActivityTrackingService.platformFor(
          isWeb: false,
          targetPlatform: targetPlatform,
        );
        expect(platform, isNot('ios'));
        expect(platform, isNot('android'));
      }

      expect(
        ActivityTrackingService.platformFor(
          isWeb: true,
          targetPlatform: TargetPlatform.iOS,
        ),
        'web',
      );
    });
  });

  group('activity record', () {
    test('carries the platform in a top-level field', () {
      final record = ActivityTrackingService.buildRecord(
        userId: 'firebase-auth-user-uid',
        action: ActivityActions.listingView,
        platform: ActivityPlatforms.ios,
        timestamp: DateTime.utc(2026, 9, 11, 10, 30),
        userName: 'Example User',
        item: 'Example Listing',
        category: 'Food & Drink',
        city: 'Lahore',
      );

      expect(record['platform'], 'ios');
      expect(record['userId'], 'firebase-auth-user-uid');
      expect(record['user'], 'Example User');
      expect(record['action'], 'listing_view');
      expect(record['item'], 'Example Listing');
      expect(record['category'], 'Food & Drink');
      expect(record['city'], 'Lahore');
      expect(record['timestamp'], '2026-09-11T10:30:00.000Z');
    });

    test('stores the timestamp of the event in UTC', () {
      final record = ActivityTrackingService.buildRecord(
        userId: 'uid',
        action: ActivityActions.login,
        platform: ActivityPlatforms.android,
        timestamp: DateTime.utc(2026, 9, 11, 10, 30).toLocal(),
      );

      expect(record['timestamp'], '2026-09-11T10:30:00.000Z');
    });

    test('omits blank details instead of storing empty strings', () {
      final record = ActivityTrackingService.buildRecord(
        userId: 'uid',
        action: ActivityActions.appOpen,
        platform: ActivityPlatforms.android,
        timestamp: DateTime.utc(2026, 9, 11),
        userName: '   ',
        item: '',
        category: null,
      );

      expect(record.containsKey('user'), isFalse);
      expect(record.containsKey('item'), isFalse);
      expect(record.containsKey('category'), isFalse);
      expect(record.containsKey('city'), isFalse);
      expect(record['platform'], 'android');
    });

    test('the platform is never left blank for a mobile event', () {
      final record = ActivityTrackingService.buildRecord(
        userId: 'uid',
        action: ActivityActions.itemSaved,
        platform: ActivityTrackingService.platformFor(
          isWeb: false,
          targetPlatform: TargetPlatform.android,
        ),
        timestamp: DateTime.utc(2026, 9, 11),
      );

      expect(record['platform'], 'android');
    });
  });

  test('activity documents go to the collection the admin reads', () {
    expect(ActivityTrackingService.collectionPath, 'userActivity');
  });
}
