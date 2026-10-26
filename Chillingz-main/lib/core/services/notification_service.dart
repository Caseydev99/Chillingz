import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../../routes/app_routes.dart';
import '../constants/app_colors.dart';
import '../navigation/app_navigator.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static final ValueNotifier<int> unreadSignal = ValueNotifier<int>(0);

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'chillingz_notifications',
    'Chillingz notifications',
    description: 'Notifications from Chillingz.',
    importance: Importance.high,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<User?>? _authSubscription;
  Map<String, dynamic>? _pendingLaunchPayload;
  Future<void>? _initializationFuture;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _localNotificationsReady = false;
  bool _permissionsRequested = false;
  Future<void>? _pendingTokenSync;
  String? _storedTokenKey;
  bool _hasSubscribedToDefaultTopics = false;

  Future<void> initialize() async {
    if (kIsWeb) return;
    _initializationFuture ??= _initialize();
    await _initializationFuture;
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitializing = true;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _initializeLocalNotifications();

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
        debugPrint('FCM token refreshed: $token');
        unawaited(_storeTokenForCurrentUser(token));
      });
      _authSubscription = _firebaseAuth.authStateChanges().listen((user) {
        if (user == null) {
          // Let the next sign-in write the token again, even if unchanged.
          _storedTokenKey = null;
          return;
        }

        unawaited(syncTokenForCurrentUser());
      });

      // Started before the permission prompt: APNs registration happens
      // whatever the user answers, so the token is available either way, and
      // awaiting the prompt here would hold the token back until it is
      // dismissed. Not awaited so neither the prompt nor the APNs wait delays
      // the first frame.
      unawaited(syncTokenForCurrentUser());

      await _requestPermissions();
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _pendingLaunchPayload = Map<String, dynamic>.from(initialMessage.data);
      }

      _isInitialized = true;
    } finally {
      _isInitializing = false;
    }
  }

  /// Collapses overlapping calls into a single run. Several triggers fire close
  /// together on a cold start or a fresh sign-in — [initialize], the
  /// [FirebaseAuth.authStateChanges] listener (which emits the current user as
  /// soon as it is listened to) and the explicit calls in `AuthProvider` — and
  /// each run otherwise repeats the APNs wait, the token fetch and the write.
  Future<void> syncTokenForCurrentUser() {
    if (kIsWeb) {
      return Future<void>.value();
    }

    return _pendingTokenSync ??= _runTokenSync().whenComplete(() {
      _pendingTokenSync = null;
    });
  }

  Future<void> _runTokenSync() async {
    // A sign-in can beat [initialize] on a cold start; the `else` branch is the
    // call made from inside [_initialize] itself, which must not recurse.
    if (!_isInitialized && !_isInitializing) {
      await initialize();
    } else {
      await _requestPermissions();
    }

    final token = await _currentToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _storeTokenForCurrentUser(token);
    await _subscribeToDefaultTopics();
  }

  /// On Apple platforms FCM cannot mint a token until APNs has handed the app a
  /// device token, and [FirebaseMessaging.getToken] throws until it does. Wait a
  /// short while for it; if it never arrives, [FirebaseMessaging.onTokenRefresh]
  /// picks the token up later.
  Future<String?> _currentToken() async {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        final apnsToken = await _waitForApnsToken();
        if (apnsToken == null) {
          debugPrint('APNs token: unavailable');
          return null;
        }

        debugPrint('APNs token: $apnsToken');
      }

      final token = await _messaging.getToken();
      debugPrint('FCM token: $token');
      return token;
    } on FirebaseException catch (error) {
      debugPrint('Skipping FCM token sync: ${error.code}');
      return null;
    }
  }

  Future<String?> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 40; attempt++) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        return apnsToken;
      }

      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    return null;
  }

  void clearUnreadSignal() {
    unreadSignal.value = 0;
  }

  Future<void> showRecentNewUserAudienceNotifications() async {
    if (kIsWeb) {
      return;
    }

    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }

    final userDocument = _firestore.collection('users').doc(user.uid);
    final userSnapshot = await userDocument.get();
    final userData = userSnapshot.data() ?? const <String, dynamic>{};
    final userCreatedAt =
        _dateValue(userData['createdAt'] ?? user.metadata.creationTime);
    final now = DateTime.now().toUtc();

    if (userCreatedAt == null ||
        now.difference(userCreatedAt.toUtc()) > const Duration(days: 7)) {
      return;
    }

    final deliveredIds =
        _stringSet(userData['deliveredNewUserNotificationIds']);
    final notifications = _firestore.collection('notifications');
    final queries = <Query<Map<String, dynamic>>>[
      notifications.where('audience', whereIn: _newUserAudienceValues),
      notifications.where('targetAudience', whereIn: _newUserAudienceValues),
      notifications.where('audienceType', whereIn: _newUserAudienceValues),
    ];
    final byId = <String, Map<String, dynamic>>{};

    for (final query in queries) {
      try {
        final snapshot = await query.limit(20).get();
        for (final doc in snapshot.docs) {
          byId[doc.id] = doc.data();
        }
      } on FirebaseException {
        continue;
      }
    }

    try {
      final snapshot = await notifications.limit(50).get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (_isNewUsersAudience(data)) {
          byId[doc.id] = data;
        }
      }
    } on FirebaseException {
      // Field-specific notification queries above are the primary path.
    }

    final newlyDeliveredIds = <String>[];
    for (final entry in byId.entries) {
      if (deliveredIds.contains(entry.key)) {
        continue;
      }

      final data = entry.value;
      if (!_isDeliverableNewUserNotification(data, now)) {
        continue;
      }

      final title = _firstString(data, const ['title', 'heading', 'subject']) ??
          'Chillingz';
      final body =
          _firstString(data, const ['message', 'body', 'description']) ?? '';
      if (title.trim().isEmpty && body.trim().isEmpty) {
        continue;
      }

      await _showLocalNotification(
        id: entry.key.hashCode & 0x7fffffff,
        title: title,
        body: body,
        payload: {
          ...data,
          'notificationId': entry.key,
          'route': AppRoutes.notifications,
        },
      );
      newlyDeliveredIds.add(entry.key);
    }

    if (newlyDeliveredIds.isNotEmpty) {
      await userDocument.set({
        'deliveredNewUserNotificationIds':
            FieldValue.arrayUnion(newlyDeliveredIds),
        'newUserNotificationsCheckedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> handlePendingLaunchNotification() async {
    final payload = _pendingLaunchPayload;
    if (payload == null) {
      return;
    }

    _pendingLaunchPayload = null;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _navigateFromPayload(payload);
  }

  Future<void> removeCurrentTokenFromUser() async {
    if (kIsWeb) {
      return;
    }

    final user = _firebaseAuth.currentUser;
    final token = await _currentToken();
    if (user == null || token == null || token.isEmpty) {
      return;
    }

    await _firestore.collection('users').doc(user.uid).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
      'fcmTokenRemovedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _storedTokenKey = null;
  }

  Future<void> _subscribeToDefaultTopics() async {
    if (_hasSubscribedToDefaultTopics) {
      return;
    }

    const subscribeTopics = <String>[
      'all_users',
      'all-users',
    ];
    const unsubscribeTopics = <String>[
      'new_users',
      'new-users',
    ];

    for (final topic in subscribeTopics) {
      try {
        await _messaging.subscribeToTopic(topic);
      } on FirebaseException {
        continue;
      }
    }

    for (final topic in unsubscribeTopics) {
      try {
        await _messaging.unsubscribeFromTopic(topic);
      } on FirebaseException {
        continue;
      }
    }

    _hasSubscribedToDefaultTopics = true;
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _authSubscription?.cancel();
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsReady) {
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
    _localNotificationsReady = true;
  }

  Future<void> _requestPermissions() async {
    if (_permissionsRequested) {
      return;
    }

    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _permissionsRequested = true;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    // Bumped here rather than in _showLocalNotification so the UI still reacts
    // on Apple platforms, where the system presents the alert itself.
    unreadSignal.value++;

    // Apple platforms already present alerts for messages that carry a
    // notification payload (see setForegroundNotificationPresentationOptions),
    // so a local notification on top of that would show the same alert twice.
    // Data-only messages are not presented by the system and still need one.
    if (notification != null && (Platform.isIOS || Platform.isMacOS)) {
      return;
    }

    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    await _showLocalNotification(
      id: message.hashCode,
      title: title ?? 'Chillingz',
      body: body ?? '',
      payload: message.data,
    );
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    await _initializeLocalNotifications();
    await _requestPermissions();
    unreadSignal.value += 1;

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('ic_launcher'),
          color: AppColors.primary,
          colorized: true,
          channelShowBadge: true,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(payload),
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    _navigateFromPayload(message.data);
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      _navigateFromPayload(const <String, dynamic>{});
      return;
    }

    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      _navigateFromPayload(decoded);
    } else {
      _navigateFromPayload(const <String, dynamic>{});
    }
  }

  void _navigateFromPayload(Map<String, dynamic> data) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    final route = _routeFromPayload(data);
    navigator.pushNamed(route);
  }

  String _routeFromPayload(Map<String, dynamic> data) {
    final rawRoute = (data['route'] ??
            data['routeName'] ??
            data['screen'] ??
            data['type'] ??
            '')
        .toString()
        .trim();

    if (rawRoute.isEmpty) {
      return AppRoutes.notifications;
    }

    if (rawRoute.startsWith('/')) {
      return rawRoute;
    }

    switch (rawRoute.toLowerCase()) {
      case 'notifications':
      case 'notification':
        return AppRoutes.notifications;
      case 'home':
      case 'bottom_nav':
      case 'bottom-nav':
        return AppRoutes.bottomNav;
      case 'events':
        return AppRoutes.events;
      case 'music':
        return AppRoutes.music;
      case 'activities':
        return AppRoutes.activities;
      case 'food':
      case 'food-drink':
      case 'food_drink':
        return AppRoutes.foodDrink;
      case 'networking':
        return AppRoutes.networking;
      case 'settings':
        return AppRoutes.settings;
      default:
        return AppRoutes.notifications;
    }
  }

  Future<void> _storeTokenForCurrentUser(String token) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || token.isEmpty) {
      return;
    }

    // onTokenRefresh also fires when FCM first mints the token, which would
    // repeat the write a token sync has just done. Skip if nothing changed.
    final tokenKey = '${user.uid}:$token';
    if (tokenKey == _storedTokenKey) {
      return;
    }

    await _firestore.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'deviceFcmToken': token,
      'deviceFcmTokens': FieldValue.arrayUnion([token]),
      'deviceTokens': FieldValue.arrayUnion([token]),
      'notificationTokens': FieldValue.arrayUnion([token]),
      'fcmTokenPlatform': _platformName,
      'fcmTokenDevice': Platform.operatingSystem,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      'notificationsEnabled': true,
    }, SetOptions(merge: true));

    _storedTokenKey = tokenKey;
  }

  String get _platformName {
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isMacOS) {
      return 'macos';
    }
    return defaultTargetPlatform.name;
  }

  static const List<String> _newUserAudienceValues = <String>[
    'New',
    'new',
    'New users',
    'new users',
    'new-users',
    'new_users',
  ];

  static bool _isNewUsersAudience(Map<String, dynamic> data) {
    final audience = _firstString(
      data,
      const ['audience', 'targetAudience', 'audienceType'],
    )?.toLowerCase();
    return audience != null &&
        _newUserAudienceValues
            .map((value) => value.toLowerCase())
            .contains(audience);
  }

  static bool _isDeliverableNewUserNotification(
    Map<String, dynamic> data,
    DateTime now,
  ) {
    final status = data['status']?.toString().trim().toLowerCase();
    if (status != null &&
        status.isNotEmpty &&
        status != 'sent' &&
        status != 'active') {
      return false;
    }

    final createdAt = _dateValue(
      data['createdAt'] ??
          data['sentAt'] ??
          data['updatedAt'] ??
          data['timestamp'],
    );
    if (createdAt == null) {
      return false;
    }

    return now.difference(createdAt.toUtc()) <= const Duration(days: 30);
  }

  static String? _firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  static Set<String> _stringSet(Object? value) {
    if (value is! Iterable) {
      return const <String>{};
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  static DateTime? _dateValue(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    try {
      final dynamicValue = value as dynamic;
      final toDate = dynamicValue.toDate;
      if (toDate is Function) {
        final parsed = toDate();
        if (parsed is DateTime) {
          return parsed;
        }
      }
    } catch (_) {
      // Firestore timestamps can also arrive as strings from admin data.
    }

    return DateTime.tryParse(value.toString());
  }
}
