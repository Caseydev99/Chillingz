import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/notification_service.dart';
import '../../../routes/app_routes.dart';
import '../../auth/models/interest_option.dart';
import '../../auth/services/tags_service.dart';
import '../models/notification_item.dart';
import '../models/profile_setting_item.dart';

class ProfileProvider extends ChangeNotifier {
  static const int minInterestSelection = 3;

  ProfileProvider({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    TagsService? tagsService,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _tagsService = tagsService ?? TagsService(firestore: firestore) {
    unawaited(_loadLastSeenNotificationAt());
    _authSubscription = _firebaseAuth.authStateChanges().listen(
          _handleAuthStateChanged,
        );
    NotificationService.unreadSignal.addListener(_handleForegroundPush);
  }

  static const String _lastSeenNotificationKey = 'notifications_last_seen_at';

  /// Fields a notification document can use to address a single user.
  static const List<String> _recipientFields = <String>[
    'userId',
    'uid',
    'authUid',
    'recipientId',
    'recipientUid',
    'targetUserId',
  ];

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final TagsService _tagsService;

  static const List<String> _moodOptions = [
    AppStrings.relaxed,
    AppStrings.energetic,
    AppStrings.spontaneous,
  ];

  static const List<InterestOption> _fallbackInterestOptions =
      <InterestOption>[];

  static const List<ProfileSettingItem> _settingItems = [
    ProfileSettingItem(
      title: AppStrings.editProfileTitle,
      iconPath: AppImages.editProfileIcon,
      routeName: AppRoutes.editProfile,
    ),
    ProfileSettingItem(
      title: AppStrings.moodSelection,
      iconPath: AppImages.moodSelectionIcon,
      routeName: AppRoutes.moodSelectionScreen,
    ),
    ProfileSettingItem(
      title: AppStrings.interestsSelection,
      iconPath: AppImages.interestsIcon,
      routeName: AppRoutes.interestsSelection,
    ),
    ProfileSettingItem(
      title: AppStrings.changePasswordTitle,
      iconPath: AppImages.changePasswordIcon,
      routeName: AppRoutes.changePassword,
    ),
    ProfileSettingItem(
      title: AppStrings.appearance,
      iconPath: AppImages.appearanceIcon,
      routeName: AppRoutes.appearance,
    ),
    ProfileSettingItem(
      title: AppStrings.locationPreferences,
      iconPath: AppImages.locationPreferenceIcon,
      hasToggle: true,
    ),
    ProfileSettingItem(
      title: AppStrings.privacyPolicy,
      iconPath: AppImages.changePasswordIcon,
      routeName: AppRoutes.privacyPolicy,
    ),
    ProfileSettingItem(
      title: AppStrings.termsConditions,
      iconPath: AppImages.changePasswordIcon,
      routeName: AppRoutes.termsConditions,
    ),
  ];

  String _selectedMood = AppStrings.relaxed;
  String _selectedAppearance = AppStrings.dark;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  final TextEditingController _nameController = TextEditingController(
    text: AppStrings.editProfileName,
  );
  final TextEditingController _emailController = TextEditingController(
    text: AppStrings.editProfileEmail,
  );
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _selectedAvatarDataUrl;
  bool _isLoadingInterests = false;
  bool _isLoadingNotifications = false;
  StreamSubscription<User?>? _authSubscription;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _notificationSubscriptions =
      <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
  final Map<String, Map<String, NotificationItem>> _notificationsBySource =
      <String, Map<String, NotificationItem>>{};
  Map<String, dynamic> _notificationUserData = const <String, dynamic>{};
  String? _notificationsUid;
  DateTime? _lastSeenNotificationAt;
  bool _hasUnseenPush = false;
  bool _isSavingMood = false;
  bool _hasLoadedInterests = false;
  List<InterestOption>? _remoteInterestOptions;
  List<NotificationItem> _remoteNotificationItems = const [];
  final List<String> _selectedInterests = <String>[];

  String get selectedMood => _selectedMood;
  String get selectedAppearance => _selectedAppearance;
  ThemeMode get themeMode {
    switch (_selectedAppearance) {
      case AppStrings.light:
        return ThemeMode.light;
      case AppStrings.system:
        return ThemeMode.system;
      case AppStrings.dark:
      default:
        return ThemeMode.dark;
    }
  }

  bool get obscureCurrentPassword => _obscureCurrentPassword;
  bool get obscureNewPassword => _obscureNewPassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  String get profileName => _nameController.text;
  String get profileEmail => _emailController.text;
  String? get selectedAvatarDataUrl => _selectedAvatarDataUrl;
  String get logoutIconPath => AppImages.logoutIcon;
  TextEditingController get nameController => _nameController;
  TextEditingController get emailController => _emailController;
  TextEditingController get currentPasswordController =>
      _currentPasswordController;
  TextEditingController get newPasswordController => _newPasswordController;
  TextEditingController get confirmPasswordController =>
      _confirmPasswordController;
  List<String> get moodOptions => _moodOptions;
  bool get isSavingMood => _isSavingMood;
  bool get isLoadingInterests => _isLoadingInterests;
  bool get isLoadingNotifications => _isLoadingNotifications;
  List<InterestOption> get interestOptions =>
      _remoteInterestOptions ?? _fallbackInterestOptions;
  List<String> get selectedInterests => List.unmodifiable(_selectedInterests);
  List<NotificationItem> get notificationItems => _remoteNotificationItems;
  int get unreadNotificationCount =>
      _remoteNotificationItems.where(_isUnseen).length;

  /// Drives the dot on the notification bell.
  bool get hasUnreadNotifications =>
      _hasUnseenPush || unreadNotificationCount > 0;
  List<NotificationItem> get fallbackNotificationItems =>
      const <NotificationItem>[];
  List<ProfileSettingItem> get settingItems => _settingItems;

  bool isInterestSelected(String interest) {
    return _selectedInterests.contains(interest);
  }

  bool toggleInterest(String interest) {
    if (_selectedInterests.contains(interest)) {
      _selectedInterests.remove(interest);
      notifyListeners();
      return true;
    }

    _selectedInterests.add(interest);
    notifyListeners();
    return true;
  }

  String? updateInterestSelection(String interest) {
    toggleInterest(interest);
    return null;
  }

  Future<void> loadInterests({bool forceRefresh = false}) async {
    if (_isLoadingInterests || (_hasLoadedInterests && !forceRefresh)) {
      return;
    }

    _isLoadingInterests = true;
    notifyListeners();

    try {
      final options = await _tagsService.fetchActiveTags();
      if (options.isNotEmpty) {
        _remoteInterestOptions = options;
      }

      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        final tags = snapshot.data()?['tags'];
        _selectedInterests
          ..clear()
          ..addAll(_stringList(tags));
      }

      _hasLoadedInterests = true;
    } finally {
      _isLoadingInterests = false;
      notifyListeners();
    }
  }

  Future<void> saveSelectedInterests() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }

    _isLoadingInterests = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'tags': _selectedInterests.toList(),
        'lastActive': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));
    } finally {
      _isLoadingInterests = false;
      notifyListeners();
    }
  }

  Future<void> saveSelectedMood() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }

    _isSavingMood = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'mood': _selectedMood,
        'lastActive': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));
    } finally {
      _isSavingMood = false;
      notifyListeners();
    }
  }

  /// Kept for the pull to refresh gesture. The list is fed by live Firestore
  /// listeners, so this only has to (re)attach them.
  Future<void> loadNotifications({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      _stopNotificationStreams();
      _remoteNotificationItems = const [];
      _isLoadingNotifications = false;
      notifyListeners();
      return;
    }

    if (_notificationsUid == user.uid &&
        _notificationSubscriptions.isNotEmpty &&
        !forceRefresh) {
      return;
    }

    await _startNotificationStreams(user);
  }

  void _handleAuthStateChanged(User? user) {
    if (user == null) {
      _stopNotificationStreams();
      _remoteNotificationItems = const [];
      _hasUnseenPush = false;
      notifyListeners();
      return;
    }

    if (_notificationsUid == user.uid &&
        _notificationSubscriptions.isNotEmpty) {
      return;
    }

    unawaited(_startNotificationStreams(user));
  }

  /// Subscribes to every place a notification for this user can live, so new
  /// documents show up without reopening the screen.
  Future<void> _startNotificationStreams(User user) async {
    _stopNotificationStreams();
    _notificationsUid = user.uid;
    _isLoadingNotifications = true;
    notifyListeners();

    try {
      final userSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      _notificationUserData = <String, dynamic>{
        ...?userSnapshot.data(),
        'authCreatedAt': user.metadata.creationTime,
      };
    } on FirebaseException {
      _notificationUserData = <String, dynamic>{
        'authCreatedAt': user.metadata.creationTime,
      };
    }

    if (_notificationsUid != user.uid) {
      // Another account signed in while the profile was being read.
      return;
    }

    _listenToNotifications(
      'user-subcollection',
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .limit(50),
    );

    for (final field in _recipientFields) {
      _listenToNotifications(
        'field-$field',
        _firestore
            .collection('notifications')
            .where(field, isEqualTo: user.uid)
            .limit(50),
      );
    }

    final audienceQueries = _audienceNotificationQueries();
    for (var index = 0; index < audienceQueries.length; index++) {
      _listenToNotifications(
        'audience-$index',
        audienceQueries[index].limit(50),
        isAudienceQuery: true,
      );
    }

    _isLoadingNotifications = false;
    _rebuildNotifications();
  }

  void _listenToNotifications(
    String sourceKey,
    Query<Map<String, dynamic>> query, {
    bool isAudienceQuery = false,
  }) {
    _notificationSubscriptions.add(
      query.snapshots().listen(
        (snapshot) {
          final items = <String, NotificationItem>{};

          for (final doc in snapshot.docs) {
            final data = doc.data();
            if (isAudienceQuery &&
                !_shouldIncludeAudienceNotification(
                  data,
                  _notificationUserData,
                )) {
              continue;
            }

            final item = NotificationItem.fromMap(data);
            if (item.title.isEmpty && item.message.isEmpty) {
              continue;
            }

            items[doc.id] = item;
          }

          _notificationsBySource[sourceKey] = items;
          _rebuildNotifications();
        },
        onError: (Object error) {
          // A missing index or a rules rejection only disables that source.
          _notificationsBySource[sourceKey] =
              const <String, NotificationItem>{};
          _rebuildNotifications();
        },
      ),
    );
  }

  void _rebuildNotifications() {
    final byDocumentId = <String, NotificationItem>{};
    for (final source in _notificationsBySource.values) {
      byDocumentId.addAll(source);
    }

    final notifications =
        byDocumentId.values
            .map((item) => item.copyWith(isUnread: _isUnseen(item)))
            .toList()
          ..sort((a, b) {
            final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });

    _remoteNotificationItems = notifications;
    _isLoadingNotifications = false;
    notifyListeners();
  }

  void _stopNotificationStreams() {
    for (final subscription in _notificationSubscriptions) {
      unawaited(subscription.cancel());
    }

    _notificationSubscriptions.clear();
    _notificationsBySource.clear();
    _notificationUserData = const <String, dynamic>{};
    _notificationsUid = null;
  }

  /// A push that arrives while the app is open lights the dot up straight
  /// away, even before the matching document reaches Firestore.
  void _handleForegroundPush() {
    _hasUnseenPush = true;
    notifyListeners();
  }

  bool _isUnseen(NotificationItem item) {
    final lastSeenAt = _lastSeenNotificationAt;
    if (lastSeenAt == null) {
      return true;
    }

    final createdAt = item.createdAt;
    if (createdAt == null) {
      return false;
    }

    return createdAt.isAfter(lastSeenAt);
  }

  /// Clears the bell dot. Called when the notifications screen is opened.
  Future<void> markNotificationsAsSeen() async {
    final seenAt = DateTime.now();
    _lastSeenNotificationAt = seenAt;
    _hasUnseenPush = false;
    NotificationService.instance.clearUnreadSignal();
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _lastSeenNotificationKey,
      seenAt.toUtc().toIso8601String(),
    );
  }

  Future<void> _loadLastSeenNotificationAt() async {
    final preferences = await SharedPreferences.getInstance();
    final storedValue = preferences.getString(_lastSeenNotificationKey);
    if (storedValue == null) {
      return;
    }

    _lastSeenNotificationAt = DateTime.tryParse(storedValue);
    notifyListeners();
  }

  List<Query<Map<String, dynamic>>> _audienceNotificationQueries() {
    const allAudienceValues = <String>[
      'All users',
      'all users',
      'all',
      'all-users',
      'all_users',
      'everyone',
      'Everyone',
    ];
    const newUserAudienceValues = <String>[
      'New users',
      'new users',
      'new-users',
      'new_users',
    ];
    final notifications = _firestore.collection('notifications');

    return <Query<Map<String, dynamic>>>[
      notifications.where('audience', whereIn: allAudienceValues),
      notifications.where('audience', whereIn: newUserAudienceValues),
      notifications.where('targetAudience', whereIn: allAudienceValues),
      notifications.where('targetAudience', whereIn: newUserAudienceValues),
      notifications.where('audienceType', whereIn: allAudienceValues),
      notifications.where('audienceType', whereIn: newUserAudienceValues),
    ];
  }

  static bool _shouldIncludeAudienceNotification(
    Map<String, dynamic> notification,
    Map<String, dynamic> user,
  ) {
    final audience = _audienceValue(notification);
    final createdAt = _dateValue(
      notification['createdAt'] ??
          notification['sentAt'] ??
          notification['updatedAt'] ??
          notification['timestamp'],
    );
    final userCreatedAt = _dateValue(
      user['createdAt'] ?? user['authCreatedAt'],
    );

    if (createdAt != null &&
        userCreatedAt != null &&
        createdAt.isBefore(userCreatedAt)) {
      return false;
    }

    if (_isNewUsersAudience(audience)) {
      if (createdAt == null || userCreatedAt == null) {
        return false;
      }

      final ageAtNotification = createdAt.difference(userCreatedAt);
      return !ageAtNotification.isNegative &&
          ageAtNotification <= const Duration(days: 7);
    }

    return _isAllUsersAudience(audience);
  }

  static String _audienceValue(Map<String, dynamic> data) {
    for (final key in const ['audience', 'targetAudience', 'audienceType']) {
      final value = data[key]?.toString().trim().toLowerCase();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  static bool _isAllUsersAudience(String audience) {
    return const {
      'all users',
      'all',
      'all-users',
      'all_users',
      'everyone',
    }.contains(audience);
  }

  static bool _isNewUsersAudience(String audience) {
    return const {
      'new',
      'new users',
      'new-users',
      'new_users',
    }.contains(audience);
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
      // Backend timestamps may also arrive as strings.
    }

    return DateTime.tryParse(value.toString());
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) {
      return const [];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void updateMood(String mood) {
    _updateSelectedMood(mood);
  }

  void updateAppearance(String appearance) {
    _updateSelectedAppearance(appearance);
  }

  void toggleCurrentPasswordVisibility() {
    _obscureCurrentPassword = !_obscureCurrentPassword;
    notifyListeners();
  }

  void toggleNewPasswordVisibility() {
    _obscureNewPassword = !_obscureNewPassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void saveProfile() {
    notifyListeners();
  }

  void updateProfileFields({
    required String name,
    required String email,
    String? avatarDataUrl,
  }) {
    _nameController.text = name.trim();
    _emailController.text = email.trim();
    if (avatarDataUrl != null && avatarDataUrl.isNotEmpty) {
      _selectedAvatarDataUrl = avatarDataUrl;
    }
    notifyListeners();
  }

  void updateAvatarDataUrl(String value) {
    _selectedAvatarDataUrl = value;
    notifyListeners();
  }

  void clearPasswordFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    notifyListeners();
  }

  void _updateSelectedMood(String mood) {
    if (_selectedMood == mood) {
      return;
    }

    _selectedMood = mood;
    notifyListeners();
  }

  void _updateSelectedAppearance(String appearance) {
    if (_selectedAppearance == appearance) {
      return;
    }

    _selectedAppearance = appearance;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    _stopNotificationStreams();
    NotificationService.unreadSignal.removeListener(_handleForegroundPush);
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
