import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/google_sign_in_config.dart';
import '../../../core/services/activity_tracking_service.dart';
import '../../../core/services/notification_service.dart';
import '../models/interest_option.dart';
import '../services/tags_service.dart';

/// Thrown when the user closes the Google account picker. Screens treat it as
/// "nothing happened" rather than an error.
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
}

class AuthProvider extends ChangeNotifier {
  static const int minInterestSelection = 3;
  static const String _staySignedInKey = 'stay_signed_in';
  static const String _sessionUserIdKey = 'session_user_id';
  static const String _sessionTokenKey = 'session_token';
  static const String _sessionSavedAtKey = 'session_saved_at';

  AuthProvider({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? firebaseFunctions,
    TagsService? tagsService,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseFunctions = firebaseFunctions ?? FirebaseFunctions.instance,
       _tagsService = tagsService ?? TagsService(firestore: firestore) {
    _sessionPreferenceFuture = _loadSessionPreference();
    unawaited(loadInterestOptions());
  }

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _firebaseFunctions;
  final TagsService _tagsService;
  final ActivityTrackingService _activityTracking =
      ActivityTrackingService.instance;
  late final Future<void> _sessionPreferenceFuture;
  Future<void>? _googleSignInInitialization;

  bool _obscureSignInPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureResetPassword = true;
  bool _obscureResetConfirmPassword = true;
  bool _stayLoggedIn = false;
  bool _agreeToTerms = false;
  String? _storedSessionUserId;
  String? _storedSessionToken;
  bool _isLoading = false;
  bool _isLoadingInterests = false;
  bool _isGuest = false;
  List<InterestOption>? _remoteInterestOptions;
  final List<String> _selectedInterests = <String>[];

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  bool get isSignedIn => currentUser != null;
  bool get isGuest => _isGuest && !isSignedIn;
  bool get obscureSignInPassword => _obscureSignInPassword;
  bool get obscureSignUpPassword => _obscureSignUpPassword;
  bool get obscureResetPassword => _obscureResetPassword;
  bool get obscureResetConfirmPassword => _obscureResetConfirmPassword;
  bool get stayLoggedIn => _stayLoggedIn;
  bool get hasStoredSession => _storedSessionUserId != null;
  String? get storedSessionToken => _storedSessionToken;
  bool get agreeToTerms => _agreeToTerms;
  bool get isLoading => _isLoading;
  bool get isLoadingInterests => _isLoadingInterests;
  bool get isGoogleSignInAvailable => GoogleSignInConfig.isAvailable;
  List<String> get selectedInterests => List.unmodifiable(_selectedInterests);
  List<InterestOption> get interestOptions =>
      _remoteInterestOptions ?? _fallbackInterestOptions;
  static const List<InterestOption> _fallbackInterestOptions =
      <InterestOption>[];

  void toggleSignInPasswordVisibility() {
    _obscureSignInPassword = !_obscureSignInPassword;
    notifyListeners();
  }

  void toggleSignUpPasswordVisibility() {
    _obscureSignUpPassword = !_obscureSignUpPassword;
    notifyListeners();
  }

  void toggleResetPasswordVisibility() {
    _obscureResetPassword = !_obscureResetPassword;
    notifyListeners();
  }

  void toggleResetConfirmPasswordVisibility() {
    _obscureResetConfirmPassword = !_obscureResetConfirmPassword;
    notifyListeners();
  }

  Future<void> initializeSessionPreference() => _sessionPreferenceFuture;

  Future<void> loadInterestOptions({bool forceRefresh = false}) async {
    if (_isLoadingInterests ||
        (_remoteInterestOptions != null && !forceRefresh)) {
      return;
    }

    _isLoadingInterests = true;
    notifyListeners();

    try {
      final options = await _tagsService.fetchActiveTags();
      if (options.isNotEmpty) {
        _remoteInterestOptions = options;
      }
    } finally {
      _isLoadingInterests = false;
      notifyListeners();
    }
  }

  Future<void> toggleStayLoggedIn(bool? value) async {
    _stayLoggedIn = value ?? false;
    notifyListeners();
    await _saveSessionPreference();
  }

  void toggleAgreeToTerms(bool? value) {
    _agreeToTerms = value ?? false;
    notifyListeners();
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

  bool isInterestSelected(String interest) {
    return _selectedInterests.contains(interest);
  }

  Future<void> signIn({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        _isGuest = false;
        await _ensureUserProfile(user);
        await _recordLogin(user);
        unawaited(_syncNotificationsForSignedInUser());
        await _persistSession(user);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    _isLoading = true;
    notifyListeners();

    try {
      final existingUser = currentUser;
      if (existingUser != null &&
          existingUser.email?.toLowerCase() == trimmedEmail.toLowerCase()) {
        _isGuest = false;
        await _saveNewUserProfile(existingUser, trimmedName);
        await _recordLogin(existingUser);
        unawaited(_syncNotificationsForSignedInUser());
        await _persistSession(existingUser);
        return;
      }

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final user = credential.user;

      if (user != null) {
        _isGuest = false;
        await _saveNewUserProfile(user, trimmedName);
        await _recordLogin(user);
        unawaited(_syncNotificationsForSignedInUser());
        await _persistSession(user);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs in with Google, creating the account on first use.
  ///
  /// The account is the same Firebase user the website creates for Google
  /// sign-ins, so favourites and interests are shared. Returns `true` when the
  /// user still needs to pick interests (a brand-new account, or one created
  /// on the website that skipped that step).
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = (await _googleCredential()).user;
      if (user == null) {
        throw FirebaseAuthException(code: 'no-current-user');
      }

      _isGuest = false;
      final needsInterests = await _ensureGoogleUserProfile(user);
      await _recordLogin(user);
      unawaited(_syncNotificationsForSignedInUser());
      await _persistSession(user);
      return needsInterests;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserCredential> _googleCredential() async {
    // The Flutter web build uses Firebase's own Google pop-up.
    if (kIsWeb) {
      return _firebaseAuth.signInWithPopup(GoogleAuthProvider());
    }

    _googleSignInInitialization ??= GoogleSignIn.instance.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? GoogleSignInConfig.iosClientId
          : null,
      serverClientId: GoogleSignInConfig.webClientId,
    );
    await _googleSignInInitialization;

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleSignInCancelled();
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Google did not return a sign-in token. Please try again.',
      );
    }
    return _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  /// Creates the profile for a first Google sign-in, the same way
  /// [signUp] does. Returns whether interests still need choosing.
  Future<bool> _ensureGoogleUserProfile(User user) async {
    final userDocument = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDocument.get();

    if (!snapshot.exists) {
      await userDocument.set(
        _newUserData(
          user: user,
          name: user.displayName ?? '',
          tags: _selectedInterests,
        ),
        SetOptions(merge: true),
      );
      return true;
    }

    return snapshot.data()?['onboarding'] != true;
  }

  Future<void> _saveNewUserProfile(User user, String displayName) async {
    if (displayName.isNotEmpty && displayName != user.displayName) {
      await user.updateDisplayName(displayName);
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
          _newUserData(user: user, name: displayName, tags: _selectedInterests),
          SetOptions(merge: true),
        );
  }

  Future<void> _ensureUserProfile(User user) async {
    final userDocument = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDocument.get();

    if (snapshot.exists) {
      return;
    }

    await userDocument.set(
      _newUserData(
        user: user,
        name: user.displayName ?? '',
        tags: const <String>[],
      ),
      SetOptions(merge: true),
    );
  }

  Future<void> saveSelectedInterests() async {
    final user = currentUser;
    if (user == null) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'tags': _selectedInterests,
        'onboarding': true,
        'lastActive': _nowIso(),
      }, SetOptions(merge: true));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyCode() async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 700));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseAuth.setLanguageCode('en');
      final callable = _firebaseFunctions.httpsCallable('sendPasswordReset');
      await callable.call<Map<String, dynamic>>({'email': email.trim()});
    } on FirebaseFunctionsException catch (error) {
      throw FirebaseAuthException(
        code: error.code,
        message: error.message ?? 'Could not send the reset email.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword() async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 800));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isGuest = false;
    _stayLoggedIn = false;
    await _saveSessionPreference();
    await _clearStoredSession();
    await NotificationService.instance.removeCurrentTokenFromUser();
    final usedGoogle =
        currentUser?.providerData.any(
          (provider) => provider.providerId == 'google.com',
        ) ??
        false;
    await _firebaseAuth.signOut();
    if (usedGoogle && !kIsWeb && _googleSignInInitialization != null) {
      // Forget the chosen Google account so the picker shows next time.
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Firebase is already signed out; this only resets the picker.
      }
    }
    _selectedInterests.clear();
    notifyListeners();
  }

  Future<void> deleteAccount({String? password}) async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Please sign in again to delete your account.',
      );
    }

    _isLoading = true;
    notifyListeners();

    try {
      final usesPassword = user.providerData.any(
        (provider) => provider.providerId == 'password',
      );
      if (usesPassword) {
        final email = user.email;
        if (email == null || email.isEmpty || password?.isNotEmpty != true) {
          throw FirebaseAuthException(
            code: 'wrong-password',
            message: 'Enter your current password to delete your account.',
          );
        }
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: password!),
        );
      } else {
        final lastSignInTime = user.metadata.lastSignInTime;
        final hasRecentLogin =
            lastSignInTime != null &&
            DateTime.now().difference(lastSignInTime) <=
                const Duration(minutes: 5);
        if (!hasRecentLogin) {
          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message: 'Please log in again before deleting your account.',
          );
        }
      }

      final uid = user.uid;
      _stayLoggedIn = false;
      await _saveSessionPreference();
      try {
        await NotificationService.instance.removeCurrentTokenFromUser();
      } on FirebaseException {
        // Token cleanup is best-effort and must never prevent an explicitly
        // confirmed account deletion.
      }
      await _firestore.collection('users').doc(uid).delete();
      await user.delete();
      await _clearStoredSession();
      _selectedInterests.clear();
      _isGuest = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    required String name,
    required String email,
    String? avatarDataUrl,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Please sign in again to update your profile.',
      );
    }

    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    _isLoading = true;
    notifyListeners();

    try {
      if (trimmedName.isNotEmpty && trimmedName != user.displayName) {
        await user.updateDisplayName(trimmedName);
      }

      await _firestore.collection('users').doc(user.uid).set({
        'authUid': user.uid,
        'id': _appUserId(user),
        'name': trimmedName,
        'email': trimmedEmail,
        'avatarUrl': avatarDataUrl?.isNotEmpty == true
            ? avatarDataUrl
            : user.photoURL ?? _avatarUrl(trimmedEmail),
        'lastActive': _nowIso(),
      }, SetOptions(merge: true));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Please sign in again to change your password.',
      );
    }

    _isLoading = true;
    notifyListeners();

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      await _firestore.collection('users').doc(user.uid).set({
        'passwordUpdatedAt': _nowIso(),
        'lastActive': _nowIso(),
      }, SetOptions(merge: true));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, Object?> _newUserData({
    required User user,
    required String name,
    required List<String> tags,
  }) {
    final email = user.email ?? '';
    final now = _nowIso();

    return {
      'authUid': user.uid,
      'avatarUrl': user.photoURL ?? _avatarUrl(email),
      'city': 'Karachi',
      'createdAt': now,
      'email': email,
      'id': _appUserId(user),
      'lastActive': now,
      'name': name,
      'notes': '',
      'onboarding': false,
      'tags': tags,
    };
  }

  Future<void> _recordLogin(User user) async {
    final now = DateTime.now();
    final utcIso = now.toUtc().toIso8601String();

    await _firestore.collection('users').doc(user.uid).set({
      'lastActive': utcIso,
      'loginAt': utcIso,
      'loginDate': now.day,
      'loginMonth': now.month,
      'loginYear': now.year,
      'loginDateLabel': _loginDateLabel(now),
    }, SetOptions(merge: true));
    _activityTracking.trackActivityInBackground(action: ActivityActions.login);
  }

  String _appUserId(User user) {
    final uid = user.uid;
    final suffixLength = uid.length < 8 ? uid.length : 8;
    return 'usr-${uid.substring(0, suffixLength)}';
  }

  String _avatarUrl(String email) {
    return 'https://i.pravatar.cc/96?u=${Uri.encodeComponent(email)}';
  }

  String _nowIso() {
    return DateTime.now().toUtc().toIso8601String();
  }

  Future<void> _loadSessionPreference() async {
    final preferences = await SharedPreferences.getInstance();
    _stayLoggedIn = preferences.getBool(_staySignedInKey) ?? false;
    _storedSessionUserId = preferences.getString(_sessionUserIdKey);
    _storedSessionToken = preferences.getString(_sessionTokenKey);
    notifyListeners();
  }

  Future<void> _saveSessionPreference() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_staySignedInKey, _stayLoggedIn);
  }

  /// Stores the signed in user id and auth token so the session survives an
  /// app restart.
  Future<void> _persistSession(User user) async {
    _stayLoggedIn = true;
    _storedSessionUserId = user.uid;

    try {
      _storedSessionToken = await user.getIdToken().timeout(
        const Duration(seconds: 8),
      );
    } catch (_) {
      // The Firebase session is already persisted by the SDK; the cached token
      // is only a convenience copy.
      _storedSessionToken = null;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_staySignedInKey, true);
    await preferences.setString(_sessionUserIdKey, user.uid);
    await preferences.setString(_sessionSavedAtKey, _nowIso());
    final token = _storedSessionToken;
    if (token != null && token.isNotEmpty) {
      await preferences.setString(_sessionTokenKey, token);
    } else {
      await preferences.remove(_sessionTokenKey);
    }

    notifyListeners();
  }

  Future<void> _clearStoredSession() async {
    _storedSessionUserId = null;
    _storedSessionToken = null;

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionUserIdKey);
    await preferences.remove(_sessionTokenKey);
    await preferences.remove(_sessionSavedAtKey);
  }

  /// Resolves the persisted session on app start.
  ///
  /// Returns `true` when the user should land straight in the app instead of
  /// the auth screens.
  Future<bool> restoreSession() async {
    await _sessionPreferenceFuture;

    final user = currentUser ?? await _firebaseAuth.authStateChanges().first;
    if (user == null) {
      _isGuest = false;
      await _clearStoredSession();
      notifyListeners();
      return false;
    }

    // Refresh the cached token so a stale copy is never handed out.
    _isGuest = false;
    await _persistSession(user);
    unawaited(NotificationService.instance.syncTokenForCurrentUser());
    // A restored session never runs the login path, so the platform is
    // detected here as well to keep tracking working without a fresh login.
    _activityTracking.trackActivityInBackground(
      action: ActivityActions.appOpen,
    );
    return true;
  }

  /// Enters a local browsing-only session without creating a Firebase user.
  void continueAsGuest() {
    if (_isGuest) {
      return;
    }
    _isGuest = true;
    notifyListeners();
  }

  String _loginDateLabel(DateTime dateTime) {
    final twoDigitHour = dateTime.hour.toString().padLeft(2, '0');
    final twoDigitMinute = dateTime.minute.toString().padLeft(2, '0');
    final twoDigitSecond = dateTime.second.toString().padLeft(2, '0');
    final twoDigitMonth = dateTime.month.toString().padLeft(2, '0');
    final twoDigitDay = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$twoDigitMonth-$twoDigitDay '
        '$twoDigitHour:$twoDigitMinute:$twoDigitSecond';
  }

  String authErrorMessage(Object error) {
    if (error is FirebaseException && error.plugin == 'cloud_firestore') {
      switch (error.code) {
        case 'permission-denied':
          return 'Database permission denied. Please deploy Firestore rules and try again.';
        case 'unavailable':
          return 'Database is unavailable. Please check your internet and try again.';
        default:
          return error.message ?? 'Could not save your profile data.';
      }
    }

    if (error is GoogleSignInException) {
      return error.code == GoogleSignInExceptionCode.clientConfigurationError
          ? 'Google sign-in is not set up for this app yet.'
          : 'Google sign-in failed. Please try again.';
    }

    if (error is! FirebaseAuthException) {
      return error.toString();
    }

    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-credential':
      case 'user-not-found':
        return 'Invalid email or password.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'wrong-password':
        return 'Current password is incorrect.';
      case 'requires-recent-login':
        return 'Please log in again before continuing.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'no-current-user':
        return 'Please sign in again to continue.';
      case 'account-exists-with-different-credential':
        return 'This email already has an account. Sign in with your email '
            'and password instead.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Google sign-in was closed before it finished.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<void> _syncNotificationsForSignedInUser() async {
    await NotificationService.instance.syncTokenForCurrentUser();
    await NotificationService.instance.showRecentNewUserAudienceNotifications();
  }
}
