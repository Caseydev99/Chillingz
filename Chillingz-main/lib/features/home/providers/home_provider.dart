import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/account_access_prompt.dart';
import '../../../core/services/activity_tracking_service.dart';
import '../../../core/services/location_permission_controller.dart';
import '../../../routes/app_routes.dart';
import '../models/chillingz_content_item.dart';
import '../models/food_cuisine_item.dart';
import '../models/home_category_item.dart';
import '../models/home_discovery_item.dart';
import '../models/music_event_item.dart';
import '../models/music_genre_item.dart';
import '../models/saved_detail_item.dart';
import '../models/saved_event_item.dart';
import '../models/social_post_item.dart';
import '../services/home_firestore_service.dart';
import '../services/location_service.dart';
import '../services/nearby_service.dart';

class HomeProvider extends ChangeNotifier {
  static const int _maximumRecommendationInterestTags = 3;

  HomeProvider({
    HomeFirestoreService? firestoreService,
    LocationService? locationService,
    NearbyService? nearbyService,
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firestoreService = firestoreService ?? HomeFirestoreService(),
       _locationService = locationService ?? LocationService(),
       _nearbyService = nearbyService ?? NearbyService(),
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance {
    _authSubscription = _firebaseAuth.authStateChanges().listen(
      _handleAuthStateChanged,
    );
    _handleAuthStateChanged(_firebaseAuth.currentUser);
    _locationPermissionController.addListener(_handleLocationPermissionChanged);
    _startPublicDataWatch();
    unawaited(loadPublicData());
  }

  final LocationPermissionController _locationPermissionController =
      LocationPermissionController.instance;
  final HomeFirestoreService _firestoreService;
  final LocationService _locationService;
  final NearbyService _nearbyService;
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final ActivityTrackingService _activityTracking =
      ActivityTrackingService.instance;
  Timer? _searchTrackingDebounce;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _userTagsSubscription;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _publicDataSubscriptions =
      <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
  Timer? _publicRefreshDebounce;

  static const List<HomeCategoryItem> _categoryItems = <HomeCategoryItem>[];
  static const List<HomeDiscoveryItem> _discoveryItems = <HomeDiscoveryItem>[];

  static const List<String> _savedFilters = [
    AppStrings.all,
    AppStrings.savedEvents,
    AppStrings.savedActivities,
    AppStrings.savedFoodDrink,
    AppStrings.savedHealthWellbeing,
    AppStrings.savedNetworking,
  ];

  static const List<String> _homeCategoryFilters = [
    AppStrings.all,
    AppStrings.music,
    AppStrings.activities,
    AppStrings.foodDrink,
    AppStrings.healthWellbeing,
    AppStrings.networking,
  ];

  static const List<String> _homeDiscoveryFilters = [AppStrings.all];

  static const List<SocialPostItem> _emptySocialPosts = <SocialPostItem>[];
  static const List<SavedEventItem> _savedEvents = <SavedEventItem>[];

  int _selectedTabIndex = 0;
  bool _locationEnabled = false;
  bool _isUpdatingLocation = false;
  bool _hasCheckedLocationPermission = false;
  bool _locationServiceEnabled = true;
  String _selectedActivityFilter = AppStrings.popular;
  String _selectedMusicFilter = AppStrings.liveNow;
  String _selectedFoodFilter = '';
  String _selectedEventFilter = AppStrings.liveNow;
  String _selectedHealthFilter = AppStrings.openNow;
  String _selectedNetworkingFilter = AppStrings.openNow;
  String _selectedSavedFilter = AppStrings.all;
  String _selectedHomeCategoryFilter = AppStrings.all;
  String _selectedHomeDiscoveryFilter = AppStrings.all;
  String _homeSearchQuery = '';
  String _musicSearchQuery = '';
  String _eventSearchQuery = '';
  String _activitySearchQuery = '';
  String _foodSearchQuery = '';
  String _savedSearchQuery = '';
  String _healthSearchQuery = '';
  String _networkingSearchQuery = '';
  bool _isLoadingPublicData = false;
  bool _refreshPublicDataAfterLoad = false;
  bool _hasRequestedPublicData = false;
  String? _publicDataError;
  List<HomeCategoryItem>? _publicCategoryItems;
  List<HomeDiscoveryItem>? _publicDiscoveryItems;
  List<String>? _publicDiscoveryFilters;
  List<MusicGenreItem>? _publicMusicGenres;
  List<MusicEventItem>? _publicMusicEvents;
  List<MusicEventItem>? _publicEventItems;
  List<SavedDetailItem>? _publicActivityItems;
  List<FoodCuisineItem>? _publicActivitySubcategories;
  List<FoodCuisineItem>? _publicFoodCuisines;
  List<SavedDetailItem>? _publicFoodPlaces;
  List<FoodCuisineItem>? _publicHealthSubcategories;
  List<SavedDetailItem>? _publicHealthItems;
  List<FoodCuisineItem>? _publicNetworkingSubcategories;
  List<SavedDetailItem>? _publicNetworkingItems;
  List<String>? _publicActivityFilters;
  List<String>? _publicFoodFilters;
  List<String>? _publicEventFilters;
  List<String>? _publicMusicFilters;
  List<String>? _publicHealthFilters;
  List<String>? _publicNetworkingFilters;
  final Set<String> _likedSavedItems = <String>{};
  final Set<String> _pendingSavedItemIds = <String>{};
  bool _isLoadingSavedItems = false;
  String? _savedItemsError;
  String? _savedItemsLoadedForUid;
  String? _locationError;
  UserLocation? _userLocation;
  Set<String> _nearbyVenueIds = <String>{};
  Set<String> _interestedTagKeys = <String>{};

  int get selectedTabIndex => _selectedTabIndex;
  bool get locationEnabled => _locationEnabled;
  bool get isUpdatingLocation => _isUpdatingLocation;
  bool get hasCheckedLocationPermission => _hasCheckedLocationPermission;
  bool get locationServiceEnabled => _locationServiceEnabled;
  bool get shouldShowLocationSheet =>
      !_locationServiceEnabled || !_locationEnabled;
  String? get locationError => _locationError;
  String? get userCity => _userLocation?.city;
  String get locationLabel {
    if (_isUpdatingLocation) {
      return 'Updating location...';
    }
    if (!_locationEnabled) {
      return AppStrings.locationNotSpecified;
    }
    final city = _userLocation?.city.trim() ?? '';
    if (city.isNotEmpty) {
      return city;
    }
    final location = _userLocation;
    if (location != null) {
      return '${location.latitude.toStringAsFixed(4)}, '
          '${location.longitude.toStringAsFixed(4)}';
    }
    return AppStrings.locationNotSpecified;
  }

  String get selectedActivityFilter =>
      _validatedFilter(_selectedActivityFilter, activityFilters);
  String get selectedMusicFilter =>
      _validatedFilter(_selectedMusicFilter, musicFilters);
  String get selectedFoodFilter =>
      _validatedFilter(_selectedFoodFilter, foodFilters);
  String get selectedEventFilter =>
      _validatedFilter(_selectedEventFilter, eventFilters);
  String get selectedHealthFilter =>
      _validatedFilter(_selectedHealthFilter, healthFilters);
  String get selectedNetworkingFilter =>
      _validatedFilter(_selectedNetworkingFilter, networkingFilters);
  String get selectedSavedFilter => _selectedSavedFilter;
  String get selectedHomeCategoryFilter => _selectedHomeCategoryFilter;
  String get selectedHomeDiscoveryFilter => _selectedHomeDiscoveryFilter;
  String get homeSearchQuery => _homeSearchQuery;
  String get musicSearchQuery => _musicSearchQuery;
  String get eventSearchQuery => _eventSearchQuery;
  String get activitySearchQuery => _activitySearchQuery;
  String get foodSearchQuery => _foodSearchQuery;
  String get savedSearchQuery => _savedSearchQuery;
  String get healthSearchQuery => _healthSearchQuery;
  String get networkingSearchQuery => _networkingSearchQuery;
  bool get isLoadingPublicData => _isLoadingPublicData;
  String? get publicDataError => _publicDataError;
  bool get hasPublicData => _hasPublicData;
  bool get isLoadingSavedItems => _isLoadingSavedItems;
  String? get savedItemsError => _savedItemsError;
  Set<String> get likedSavedItems => Set<String>.unmodifiable(_likedSavedItems);
  bool isSavedItemPending(String id) => _pendingSavedItemIds.contains(id);
  List<HomeCategoryItem> get categoryItems =>
      _publicOrFallback(_publicCategoryItems, _categoryItems);
  List<HomeDiscoveryItem> get discoveryItems =>
      _publicOrFallback(_publicDiscoveryItems, _discoveryItems);
  List<String> get activityFilters =>
      _publicOrFallback(_publicActivityFilters, const []);
  List<String> get musicFilters =>
      _publicOrFallback(_publicMusicFilters, const []);
  List<String> get foodFilters =>
      _publicOrFallback(_publicFoodFilters, const []);
  List<String> get eventFilters =>
      _publicOrFallback(_publicEventFilters, const []);
  List<String> get healthFilters =>
      _publicOrFallback(_publicHealthFilters, const []);
  List<String> get networkingFilters =>
      _publicOrFallback(_publicNetworkingFilters, const []);
  List<String> get savedFilters => _savedFilters;
  List<String> get homeCategoryFilters => _homeCategoryFilters;
  List<String> get homeDiscoveryFilters =>
      _publicOrFallback(_publicDiscoveryFilters, _homeDiscoveryFilters);
  List<FoodCuisineItem> get activitySubcategories => _filteredSubcategories(
    _publicActivitySubcategories,
    _activitySearchQuery,
  );
  List<MusicGenreItem> get musicGenres =>
      _publicOrFallback(_publicMusicGenres, const []);
  List<MusicEventItem> get musicEvents {
    final normalizedQuery = _musicSearchQuery.trim().toLowerCase();
    final source = _publicOrFallback(
      _publicMusicEvents,
      const <MusicEventItem>[],
    );
    return source.where((item) {
      final matchesFilter = _matchesMusicFilter(item);
      final matchesSearch =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.location.toLowerCase().contains(normalizedQuery) ||
          item.headliner.toLowerCase().contains(normalizedQuery) ||
          item.subcategory.toLowerCase().contains(normalizedQuery) ||
          item.venueName.toLowerCase().contains(normalizedQuery) ||
          item.timeLabel.toLowerCase().contains(normalizedQuery);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<MusicEventItem> musicEventsForGenre(MusicGenreItem genre) {
    final genreKeys = {
      _normalizedGenreKey(genre.id),
      _normalizedGenreKey(genre.title),
    }..remove('');

    return _allMusicEvents.where((item) {
      final itemGenreKey = _normalizedGenreKey(item.genre);
      return itemGenreKey.isNotEmpty && genreKeys.contains(itemGenreKey);
    }).toList();
  }

  List<MusicEventItem> get eventItems {
    final normalizedQuery = _eventSearchQuery.trim().toLowerCase();
    final source = _publicOrFallback(
      _publicEventItems,
      const <MusicEventItem>[],
    );
    return source.where((item) {
      final matchesFilter = _matchesEventFilter(item);
      final matchesSearch =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.location.toLowerCase().contains(normalizedQuery) ||
          item.headliner.toLowerCase().contains(normalizedQuery) ||
          item.subcategory.toLowerCase().contains(normalizedQuery) ||
          item.venueName.toLowerCase().contains(normalizedQuery) ||
          item.timeLabel.toLowerCase().contains(normalizedQuery);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<SavedDetailItem> get activityItems {
    final source =
        _publicOrFallback(_publicActivityItems, const <SavedDetailItem>[]);
    final normalizedQuery = _activitySearchQuery.trim().toLowerCase();
    return source.where((item) {
      final matchesFilter = _matchesActivityFilter(item);
      final matchesSearch = normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.category.toLowerCase().contains(normalizedQuery) ||
          item.venueName.toLowerCase().contains(normalizedQuery) ||
          item.subcategory.toLowerCase().contains(normalizedQuery) ||
          item.activityType.toLowerCase().contains(normalizedQuery) ||
          (item.feature ?? '').toLowerCase().contains(normalizedQuery);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<FoodCuisineItem> get foodCuisines {
    final normalizedQuery = _foodSearchQuery.trim().toLowerCase();
    final source = _publicOrFallback(
      _publicFoodCuisines,
      const <FoodCuisineItem>[],
    );
    return source.where((item) {
      return normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  List<FoodCuisineItem> get healthSubcategories =>
      _filteredSubcategories(_publicHealthSubcategories, _healthSearchQuery);

  List<FoodCuisineItem> get networkingSubcategories => _filteredSubcategories(
    _publicNetworkingSubcategories,
    _networkingSearchQuery,
  );

  List<SavedDetailItem> get foodPlaces {
    final normalizedQuery = _foodSearchQuery.trim().toLowerCase();
    final source = _publicOrFallback(
      _publicFoodPlaces,
      const <SavedDetailItem>[],
    );
    return source.where((item) {
      final matchesFilter = _matchesFoodFilter(item);
      final matchesSearch =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.category.toLowerCase().contains(normalizedQuery) ||
          item.venueName.toLowerCase().contains(normalizedQuery) ||
          item.subcategory.toLowerCase().contains(normalizedQuery) ||
          item.activityType.toLowerCase().contains(normalizedQuery) ||
          (item.feature ?? '').toLowerCase().contains(normalizedQuery);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<SavedDetailItem> get healthItems {
    final normalizedQuery = _healthSearchQuery.trim().toLowerCase();
    final source = _publicOrFallback(
      _publicHealthItems,
      const <SavedDetailItem>[],
    );
    return source.where((item) {
      final matchesFilter = _matchesHealthFilter(item);
      final matchesSearch =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.category.toLowerCase().contains(normalizedQuery) ||
          item.venueName.toLowerCase().contains(normalizedQuery) ||
          item.subcategory.toLowerCase().contains(normalizedQuery) ||
          item.activityType.toLowerCase().contains(normalizedQuery);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<SavedDetailItem> get networkingItems {
    final normalizedQuery = _networkingSearchQuery.trim().toLowerCase();
    final source = _publicOrFallback(
      _publicNetworkingItems,
      const <SavedDetailItem>[],
    );
    return source.where((item) {
      final matchesFilter = _matchesNetworkingFilter(item);
      final matchesSearch =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.category.toLowerCase().contains(normalizedQuery) ||
          item.venueName.toLowerCase().contains(normalizedQuery) ||
          item.subcategory.toLowerCase().contains(normalizedQuery) ||
          item.activityType.toLowerCase().contains(normalizedQuery);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  bool get _hasRemoteMusicEvents =>
      _publicMusicEvents != null && _publicMusicEvents!.isNotEmpty;
  bool get _hasRemoteEventItems =>
      _publicEventItems != null && _publicEventItems!.isNotEmpty;
  bool get _hasRemoteFoodPlaces =>
      _publicFoodPlaces != null && _publicFoodPlaces!.isNotEmpty;
  bool get _hasRemoteHealthItems =>
      _publicHealthItems != null && _publicHealthItems!.isNotEmpty;
  bool get _hasRemoteNetworkingItems =>
      _publicNetworkingItems != null && _publicNetworkingItems!.isNotEmpty;
  bool get _hasPublicData =>
      (_publicCategoryItems?.isNotEmpty ?? false) ||
      (_publicDiscoveryItems?.isNotEmpty ?? false) ||
      (_publicMusicGenres?.isNotEmpty ?? false) ||
      _hasRemoteMusicEvents ||
      _hasRemoteEventItems ||
      (_publicActivityItems?.isNotEmpty ?? false) ||
      (_publicActivitySubcategories?.isNotEmpty ?? false) ||
      (_publicFoodCuisines?.isNotEmpty ?? false) ||
      _hasRemoteFoodPlaces ||
      (_publicHealthSubcategories?.isNotEmpty ?? false) ||
      _hasRemoteHealthItems ||
      (_publicNetworkingSubcategories?.isNotEmpty ?? false) ||
      _hasRemoteNetworkingItems;

  List<HomeCategoryItem> get filteredCategoryItems {
    final normalizedQuery = _homeSearchQuery.trim().toLowerCase();
    return categoryItems.where((item) {
      final matchesFilter =
          _selectedHomeCategoryFilter == AppStrings.all ||
          item.title == _selectedHomeCategoryFilter ||
          item.id.toLowerCase() == _selectedHomeCategoryFilter.toLowerCase();
      final matchesSearch = normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          _categoryHasSearchMatch(item, normalizedQuery);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  int _forYouRefreshToken = 0;

  int get forYouRefreshToken => _forYouRefreshToken;

  /// Reshuffles the "Chillingz For You" recommendations using the same
  /// selected interests, so the user can request a different set of
  /// suggestions without changing their interests.
  void refreshForYouRecommendations() {
    _forYouRefreshToken++;
    notifyListeners();
  }

  List<HomeDiscoveryItem> get filteredDiscoveryItems {
    final normalizedQuery = _homeSearchQuery.trim().toLowerCase();
    final items = <HomeDiscoveryItem>[];

    for (final item in discoveryItems) {
      final contentItems = _contentItemsForInterestedTags(item);
      if (contentItems.isEmpty) {
        continue;
      }

      final matchesFilter = _matchesDiscoveryFilter(item);
      final matchesSearch =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.tag.toLowerCase().contains(normalizedQuery) ||
          item.tags.any((tag) => tag.toLowerCase().contains(normalizedQuery));
      if (!matchesFilter || !matchesSearch) {
        continue;
      }

      final matchingTags = contentItems
          .expand((contentItem) => contentItem.tags ?? const <String>[])
          .where((tag) => _interestedTagKeys.contains(_normalizedGenreKey(tag)))
          .toSet()
          .toList();
      if (matchingTags.isEmpty) {
        continue;
      }

      items.add(
        HomeDiscoveryItem(
          id: item.id,
          title: item.title,
          imagePath: item.imagePath,
          tag: matchingTags.first,
          tags: matchingTags,
          isNature: item.isNature,
          contentItems: contentItems,
        ),
      );
    }

    return _balancedDiscoveryItems(items);
  }

  List<HomeDiscoveryItem> _balancedDiscoveryItems(
    List<HomeDiscoveryItem> candidates,
  ) {
    const visibleRecommendationCount = 6;
    final selectedTags = _interestedTagKeys.toList();
    if (selectedTags.isEmpty || candidates.isEmpty) {
      return const <HomeDiscoveryItem>[];
    }

    final baseTarget = visibleRecommendationCount ~/ selectedTags.length;
    final remainder = visibleRecommendationCount % selectedTags.length;
    final targets = <String, int>{
      for (var index = 0; index < selectedTags.length; index++)
        selectedTags[index]: baseTarget + (index < remainder ? 1 : 0),
    };
    final allocatedByTag = <String, int>{
      for (final tag in selectedTags) tag: 0,
    };
    final usedIds = <String>{};
    final balanced = <HomeDiscoveryItem>[];

    // Every tap on the "For You" refresh button bumps the token, which
    // reshuffles the candidate pool so a new mix of matching recommendations
    // is picked without touching the user's selected interests. Using the
    // token as the shuffle seed keeps the order stable across rebuilds that
    // aren't triggered by a refresh (e.g. typing in the search bar).
    final orderedCandidates = _forYouRefreshToken == 0
        ? candidates
        : (List<HomeDiscoveryItem>.of(candidates)
            ..shuffle(Random(_forYouRefreshToken)));

    while (balanced.length < visibleRecommendationCount) {
      var allocatedInRound = false;
      for (final tagKey in selectedTags) {
        if (balanced.length >= visibleRecommendationCount ||
            allocatedByTag[tagKey]! >= targets[tagKey]!) {
          continue;
        }

        HomeDiscoveryItem? match;
        for (final candidate in orderedCandidates) {
          if (!usedIds.contains(candidate.id) &&
              _itemTagKeys(candidate).contains(tagKey)) {
            match = candidate;
            break;
          }
        }
        if (match == null) {
          continue;
        }

        final matchingLabel = match.tags.firstWhere(
          (tag) => _normalizedGenreKey(tag) == tagKey,
          orElse: () => match!.tag,
        );
        balanced.add(_discoveryItemWithPrimaryTag(match, matchingLabel));
        usedIds.add(match.id);
        allocatedByTag[tagKey] = allocatedByTag[tagKey]! + 1;
        allocatedInRound = true;
      }
      if (!allocatedInRound) {
        break;
      }
    }

    // Keep the remainder as the swipe-replacement pool. It is placed after
    // the balanced six so the initially visible set remains evenly split.
    for (final candidate in orderedCandidates) {
      if (usedIds.add(candidate.id)) {
        balanced.add(candidate);
      }
    }
    return balanced;
  }

  static HomeDiscoveryItem _discoveryItemWithPrimaryTag(
    HomeDiscoveryItem item,
    String primaryTag,
  ) {
    return HomeDiscoveryItem(
      id: item.id,
      title: item.title,
      imagePath: item.imagePath,
      tag: primaryTag,
      tags: item.tags,
      isNature: item.isNature,
      contentItems: item.contentItems,
    );
  }

  HomeDiscoveryDestination? discoveryDestination(HomeDiscoveryItem item) {
    final separator = item.id.indexOf(':');
    final documentId = separator < 0
        ? item.id
        : item.id.substring(separator + 1);

    final music = _firstById(_allMusicEvents, documentId, (item) => item.id);
    if (music != null) {
      return HomeDiscoveryDestination(
        routeName: AppRoutes.musicEventDetail,
        arguments: music,
      );
    }
    final event = _firstById(_allEventItems, documentId, (item) => item.id);
    if (event != null) {
      return HomeDiscoveryDestination(
        routeName: AppRoutes.eventDetail,
        arguments: event,
      );
    }
    final activity = _firstById(
      _allActivityItems,
      documentId,
      (item) => item.id,
    );
    if (activity != null) {
      return HomeDiscoveryDestination(
        routeName: AppRoutes.activityDetail,
        arguments: activity,
      );
    }
    final food = _firstById(_allFoodPlaces, documentId, (item) => item.id);
    if (food != null) {
      return HomeDiscoveryDestination(
        routeName: AppRoutes.foodPlaceDetail,
        arguments: food,
      );
    }
    final health = _firstById(_allHealthItems, documentId, (item) => item.id);
    if (health != null) {
      return HomeDiscoveryDestination(
        routeName: AppRoutes.healthDetail,
        arguments: health,
      );
    }
    final networking = _firstById(
      _allNetworkingItems,
      documentId,
      (item) => item.id,
    );
    if (networking != null) {
      return HomeDiscoveryDestination(
        routeName: AppRoutes.networkingDetail,
        arguments: networking,
      );
    }
    return null;
  }

  static T? _firstById<T>(
    Iterable<T> items,
    String id,
    String Function(T item) idOf,
  ) {
    for (final item in items) {
      if (idOf(item) == id) {
        return item;
      }
    }
    return null;
  }

  List<SocialPostItem> get socialPosts => _emptySocialPosts;
  List<SocialPostItem> get activitySocialPosts => _emptySocialPosts;
  List<SocialPostItem> get foodSocialPosts => _emptySocialPosts;
  List<SocialPostItem> get eventSocialPosts => _emptySocialPosts;
  List<SocialPostItem> get healthSocialPosts => _emptySocialPosts;
  List<SocialPostItem> get networkingSocialPosts => _emptySocialPosts;
  List<SavedEventItem> get savedEvents => _savedEvents;


  bool _categoryHasSearchMatch(HomeCategoryItem category, String query) {
    final title = category.title.toLowerCase();
    final id = category.id.toLowerCase();
    if (title.contains(AppStrings.music.toLowerCase()) ||
        id.contains('music')) {
      return _allMusicEvents
          .any((item) => _musicEventMatchesSearch(item, query));
    }
    if (title.contains(AppStrings.events.toLowerCase()) ||
        id.contains('event')) {
      return _allEventItems
          .any((item) => _musicEventMatchesSearch(item, query));
    }
    if (title.contains(AppStrings.activities.toLowerCase()) ||
        title.contains(AppStrings.activitiesAdventure.toLowerCase()) ||
        id.contains('activit')) {
      return _allActivityItems.any((item) => _detailMatchesSearch(item, query));
    }
    if (title.contains(AppStrings.foodDrink.toLowerCase()) ||
        id.contains('food')) {
      return _allFoodPlaces.any((item) => _detailMatchesSearch(item, query));
    }
    if (title.contains(AppStrings.healthWellbeing.toLowerCase()) ||
        id.contains('health')) {
      return _allHealthItems.any((item) => _detailMatchesSearch(item, query));
    }
    if (title.contains(AppStrings.networking.toLowerCase()) ||
        id.contains('network')) {
      return _allNetworkingItems
          .any((item) => _detailMatchesSearch(item, query));
    }
    return false;
  }

  static bool _musicEventMatchesSearch(MusicEventItem item, String query) {
    return item.title.toLowerCase().contains(query) ||
        item.location.toLowerCase().contains(query) ||
        (item.genre ?? '').toLowerCase().contains(query) ||
        (item.feature ?? '').toLowerCase().contains(query);
  }

  static bool _detailMatchesSearch(SavedDetailItem item, String query) {
    return item.title.toLowerCase().contains(query) ||
        item.category.toLowerCase().contains(query) ||
        item.subcategory.toLowerCase().contains(query) ||
        (item.feature ?? '').toLowerCase().contains(query) ||
        item.distance.toLowerCase().contains(query);
  }

  List<SavedEventItem> get filteredSavedEvents {
    final normalizedQuery = _savedSearchQuery.trim().toLowerCase();
    if (_selectedSavedFilter != AppStrings.all &&
        _selectedSavedFilter != AppStrings.savedEvents) {
      return const [];
    }

    final savedEvents = [
      ..._allMusicEvents.map(_musicEventToSavedEvent),
      ..._allEventItems.map(_musicEventToSavedEvent),
    ];

    return savedEvents.where((item) {
      final isSaved = _likedSavedItems.contains(item.id);
      final matchesSearch =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.location.toLowerCase().contains(normalizedQuery);
      return isSaved && matchesSearch;
    }).toList();
  }

  List<SavedDetailItem> get savedActivities {
    final normalizedQuery = _savedSearchQuery.trim().toLowerCase();
    if (_selectedSavedFilter != AppStrings.all &&
        _selectedSavedFilter != AppStrings.savedActivities) {
      return const [];
    }

    return _allActivityItems.where((item) {
      return _likedSavedItems.contains(item.id) &&
          _matchesSavedDetailSearch(item, normalizedQuery);
    }).toList();
  }

  List<SavedDetailItem> get savedFoodAndDrinks {
    final normalizedQuery = _savedSearchQuery.trim().toLowerCase();
    if (_selectedSavedFilter != AppStrings.all &&
        _selectedSavedFilter != AppStrings.savedFoodDrink) {
      return const [];
    }

    return _allFoodPlaces.where((item) {
      return _likedSavedItems.contains(item.id) &&
          _matchesSavedDetailSearch(item, normalizedQuery);
    }).toList();
  }

  List<SavedDetailItem> get savedHealthWellbeing {
    final normalizedQuery = _savedSearchQuery.trim().toLowerCase();
    if (_selectedSavedFilter != AppStrings.all &&
        _selectedSavedFilter != AppStrings.savedHealthWellbeing) {
      return const [];
    }

    return _allHealthItems.where((item) {
      return _likedSavedItems.contains(item.id) &&
          _matchesSavedDetailSearch(item, normalizedQuery);
    }).toList();
  }

  List<SavedDetailItem> get savedNetworking {
    final normalizedQuery = _savedSearchQuery.trim().toLowerCase();
    if (_selectedSavedFilter != AppStrings.all &&
        _selectedSavedFilter != AppStrings.savedNetworking) {
      return const [];
    }

    return _allNetworkingItems.where((item) {
      return _likedSavedItems.contains(item.id) &&
          _matchesSavedDetailSearch(item, normalizedQuery);
    }).toList();
  }

  MusicEventItem savedEventToMusicEvent(SavedEventItem item) {
    for (final event in [..._allMusicEvents, ..._allEventItems]) {
      if (event.id == item.id) {
        return event;
      }
    }

    return MusicEventItem(
      id: item.id,
      title: item.title,
      location: item.location,
      imagePath: item.imagePath,
      badgeText: item.badgeText,
      rating: AppStrings.defaultRating,
      priceLabel: item.priceLabel,
    );
  }

  List<SocialPostItem> socialPostsForMusicEvent(MusicEventItem item) {
    return item.socialPosts;
  }

  static SavedEventItem _musicEventToSavedEvent(MusicEventItem item) {
    return SavedEventItem(
      id: item.id,
      title: item.title,
      location: item.location,
      imagePath: item.imagePath,
      badgeText: item.badgeText,
      priceLabel: item.priceLabel,
    );
  }

  static bool _matchesSavedDetailSearch(
    SavedDetailItem item,
    String normalizedQuery,
  ) {
    return normalizedQuery.isEmpty ||
        item.title.toLowerCase().contains(normalizedQuery) ||
        item.category.toLowerCase().contains(normalizedQuery);
  }

  static String _normalizedGenreKey(String? value) {
    return (value ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  List<ChillingzContentItem> _contentItemsForInterestedTags(
    HomeDiscoveryItem item,
  ) {
    if (_interestedTagKeys.isEmpty) {
      return const <ChillingzContentItem>[];
    }

    return item.contentItems.where((contentItem) {
      final contentTagKeys = <String>{
        ...?contentItem.tags?.map(_normalizedGenreKey),
      }..remove('');
      return contentTagKeys.isNotEmpty &&
          contentTagKeys.any(_interestedTagKeys.contains);
    }).toList();
  }

  static Set<String> _itemTagKeys(HomeDiscoveryItem item) {
    return <String>{
      _normalizedGenreKey(item.tag),
      ...item.tags.map(_normalizedGenreKey),
    }..remove('');
  }

  bool _matchesDiscoveryFilter(HomeDiscoveryItem item) {
    if (_selectedHomeDiscoveryFilter == AppStrings.all) {
      return true;
    }

    final filterKey = _normalizedGenreKey(_selectedHomeDiscoveryFilter);
    if (filterKey.isEmpty) {
      return true;
    }

    return _itemTagKeys(item).contains(filterKey);
  }

  static List<FoodCuisineItem> _filteredSubcategories(
    List<FoodCuisineItem>? source,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    return _publicOrFallbackStatic(source, const <FoodCuisineItem>[]).where((
      item,
    ) {
      return normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  static List<T> _publicOrFallbackStatic<T>(List<T>? values, List<T> fallback) {
    if (values != null) {
      return values;
    }
    return const [];
  }

  bool _matchesMusicFilter(MusicEventItem item) {
    final filter = selectedMusicFilter;
    if (filter == AppStrings.nearby) {
      return _isNearbyMusicEvent(item);
    }

    if (_publicMusicFilters?.isNotEmpty ?? false) {
      return _matchesMusicEventFilter(item, filter);
    }

    return true;
  }

  bool _matchesEventFilter(MusicEventItem item) {
    final filter = selectedEventFilter;
    if (filter == AppStrings.nearby) {
      return _isNearbyMusicEvent(item);
    }

    if (_publicEventFilters?.isNotEmpty ?? false) {
      return _matchesMusicEventFilter(item, filter);
    }

    return true;
  }

  bool _matchesFoodFilter(SavedDetailItem item) {
    final filter = selectedFoodFilter;
    if (filter == AppStrings.nearbyLabel) {
      return _isNearbyDetailItem(item);
    }

    if (_publicFoodFilters?.isNotEmpty ?? false) {
      return _matchesDetailFilter(item, filter);
    }

    return true;
  }

  bool _matchesHealthFilter(SavedDetailItem item) {
    final filter = selectedHealthFilter;
    if (filter == AppStrings.nearbyLabel) {
      return _isNearbyDetailItem(item);
    }

    if (_publicHealthFilters?.isNotEmpty ?? false) {
      return _matchesDetailFilter(item, filter);
    }

    return true;
  }

  bool _matchesNetworkingFilter(SavedDetailItem item) {
    final filter = selectedNetworkingFilter;
    if (filter == AppStrings.nearbyLabel) {
      return _isNearbyDetailItem(item);
    }

    if (_publicNetworkingFilters?.isNotEmpty ?? false) {
      return _matchesDetailFilter(item, filter);
    }

    return true;
  }

  bool _matchesActivityFilter(SavedDetailItem item) {
    final filter = selectedActivityFilter;
    if (_publicActivityFilters?.isNotEmpty ?? false) {
      return _matchesDetailFilter(item, filter);
    }

    return true;
  }

  static bool _matchesDetailFilter(SavedDetailItem item, String filter) {
    final filterKey = _normalizedGenreKey(filter);
    if (filterKey.isEmpty) {
      return true;
    }

    return [
      item.feature,
      item.subcategory,
      item.activityType,
      item.category,
    ].any((value) => _normalizedGenreKey(value).contains(filterKey));
  }

  static bool _matchesMusicEventFilter(MusicEventItem item, String filter) {
    final filterKey = _normalizedGenreKey(filter);
    if (filterKey.isEmpty) {
      return true;
    }

    return [
      item.feature,
      item.subcategory,
      item.genre,
      item.headliner,
    ].any((value) => _normalizedGenreKey(value).contains(filterKey));
  }

  bool _isNearbyMusicEvent(MusicEventItem item) {
    return _locationEnabled &&
        (_nearbyVenueIds.contains(item.id) ||
            _nearbyService.isNearbyVenue(
              userLocation: _userLocation,
              venueCity: item.city,
              venueLatitude: item.latitude,
              venueLongitude: item.longitude,
            ));
  }

  String distanceLabelFor(SavedDetailItem item) {
    return _distanceLabel(item.distance, item.latitude, item.longitude);
  }

  String distanceLabelForEvent(MusicEventItem item) {
    return _distanceLabel('', item.latitude, item.longitude);
  }

  String _distanceLabel(String stored, double? latitude, double? longitude) {
    final existing = stored.trim();
    if (existing.isNotEmpty) {
      return existing;
    }

    final location = _userLocation;
    if (location == null || latitude == null || longitude == null) {
      return '';
    }

    final miles =
        NearbyService.distanceBetweenKm(
          location.latitude,
          location.longitude,
          latitude,
          longitude,
        ) *
        0.621371;
    if (miles < 0.1) {
      return '0.1 mi';
    }
    if (miles >= 100) {
      return '${miles.round()} mi';
    }
    return '${miles.toStringAsFixed(1)} mi';
  }

  bool _isNearbyDetailItem(SavedDetailItem item) {
    return _locationEnabled &&
        (_nearbyVenueIds.contains(item.id) ||
            _nearbyService.isNearbyVenue(
              userLocation: _userLocation,
              venueCity: item.city,
              venueLatitude: item.latitude,
              venueLongitude: item.longitude,
            ));
  }

  List<MusicEventItem> get _allMusicEvents =>
      _publicOrFallback(_publicMusicEvents, const []);
  List<MusicEventItem> get _allEventItems =>
      _publicOrFallback(_publicEventItems, const []);
  List<SavedDetailItem> get _allActivityItems =>
      _publicOrFallback(_publicActivityItems, const []);
  List<SavedDetailItem> get _allFoodPlaces =>
      _publicOrFallback(_publicFoodPlaces, const []);
  List<SavedDetailItem> get _allHealthItems =>
      _publicOrFallback(_publicHealthItems, const []);
  List<SavedDetailItem> get _allNetworkingItems =>
      _publicOrFallback(_publicNetworkingItems, const []);

  Future<void> loadPublicData({bool forceRefresh = false}) async {
    if (_isLoadingPublicData) {
      if (forceRefresh) {
        _refreshPublicDataAfterLoad = true;
      }
      return;
    }

    if (_hasRequestedPublicData && _publicDataError == null && !forceRefresh) {
      return;
    }

    _isLoadingPublicData = true;
    _hasRequestedPublicData = true;
    _publicDataError = null;
    notifyListeners();

    try {
      final data = await _firestoreService.fetchPublicHomeData(
        source: Source.server,
      );
      _applyPublicData(data);
    } catch (error) {
      _publicDataError = error.toString();
      if (!_hasPublicData) {
        _clearPublicData();
      }
    } finally {
      _isLoadingPublicData = false;
      notifyListeners();
      if (_refreshPublicDataAfterLoad) {
        _refreshPublicDataAfterLoad = false;
        unawaited(loadPublicData(forceRefresh: true));
      }
    }
  }

  void _startPublicDataWatch() {
    const collectionNames = [
      'categories',
      'genres',
      'subcategories',
      'subcategoriesContent',
      'listingCategories',
      'tags',
    ];

    for (final collectionName in collectionNames) {
      var hasSeenInitialSnapshot = false;
      _publicDataSubscriptions.add(
        _firestore.collection(collectionName).snapshots().listen((_) {
          if (!hasSeenInitialSnapshot) {
            hasSeenInitialSnapshot = true;
            return;
          }
          _publicRefreshDebounce?.cancel();
          _publicRefreshDebounce = Timer(
            const Duration(milliseconds: 450),
            () => unawaited(loadPublicData(forceRefresh: true)),
          );
        }),
      );
    }
  }

  void _applyPublicData(HomeFirestoreData data) {
    _publicCategoryItems = data.categories;
    _publicDiscoveryItems = data.discoveryItems;
    _publicDiscoveryFilters = data.discoveryFilters;
    _publicMusicGenres = data.musicGenres;
    _publicMusicEvents = data.musicEvents;
    _publicEventItems = data.eventItems;
    _publicActivityItems = data.activityItems;
    _publicActivitySubcategories = data.activitySubcategories;
    _publicFoodCuisines = data.foodCuisines;
    _publicFoodPlaces = data.foodPlaces;
    _publicHealthSubcategories = data.healthSubcategories;
    _publicHealthItems = data.healthItems;
    _publicNetworkingSubcategories = data.networkingSubcategories;
    _publicNetworkingItems = data.networkingItems;
    _publicActivityFilters = data.activityFilters;
    _publicFoodFilters = data.foodFilters;
    _publicEventFilters = data.eventFilters;
    _publicMusicFilters = data.musicFilters;
    _publicHealthFilters = data.healthFilters;
    _publicNetworkingFilters = data.networkingFilters;
  }

  void _clearPublicData() {
    _publicCategoryItems = const <HomeCategoryItem>[];
    _publicDiscoveryItems = const <HomeDiscoveryItem>[];
    _publicDiscoveryFilters = const <String>[];
    _publicMusicGenres = const <MusicGenreItem>[];
    _publicMusicEvents = const <MusicEventItem>[];
    _publicEventItems = const <MusicEventItem>[];
    _publicActivityItems = const <SavedDetailItem>[];
    _publicActivitySubcategories = const <FoodCuisineItem>[];
    _publicFoodCuisines = const <FoodCuisineItem>[];
    _publicFoodPlaces = const <SavedDetailItem>[];
    _publicHealthSubcategories = const <FoodCuisineItem>[];
    _publicHealthItems = const <SavedDetailItem>[];
    _publicNetworkingSubcategories = const <FoodCuisineItem>[];
    _publicNetworkingItems = const <SavedDetailItem>[];
    _publicActivityFilters = const <String>[];
    _publicFoodFilters = const <String>[];
    _publicEventFilters = const <String>[];
    _publicMusicFilters = const <String>[];
    _publicHealthFilters = const <String>[];
    _publicNetworkingFilters = const <String>[];
  }

  List<T> _publicOrFallback<T>(List<T>? values, List<T> fallback) {
    if (values != null) {
      return values;
    }
    return const [];
  }

  static String _validatedFilter(String selectedFilter, List<String> filters) {
    if (selectedFilter.trim().isEmpty) {
      return '';
    }
    if (filters.isEmpty || filters.contains(selectedFilter)) {
      return selectedFilter;
    }
    return filters.first;
  }

  List<SavedDetailItem> foodCuisinePlaces(String cuisineId) {
    final cuisineKey = _normalizedGenreKey(cuisineId);
    if (cuisineKey.isEmpty) {
      return const [];
    }

    return _allFoodPlaces.where((place) {
      return _normalizedGenreKey(place.category).contains(cuisineKey) ||
          _normalizedGenreKey(place.feature).contains(cuisineKey) ||
          _normalizedGenreKey(place.subcategory).contains(cuisineKey);
    }).toList();
  }

  List<SavedDetailItem> foodCuisinePlacesForItem(FoodCuisineItem cuisine) {
    return _detailItemsForSubcategory(_allFoodPlaces, cuisine);
  }

  List<SavedDetailItem> activitySubcategoryItems(FoodCuisineItem subcategory) {
    return _detailItemsForSubcategory(_allActivityItems, subcategory);
  }

  List<SavedDetailItem> healthSubcategoryItems(FoodCuisineItem subcategory) {
    return _detailItemsForSubcategory(_allHealthItems, subcategory);
  }

  List<SavedDetailItem> networkingSubcategoryItems(
    FoodCuisineItem subcategory,
  ) {
    return _detailItemsForSubcategory(_allNetworkingItems, subcategory);
  }

  static List<SavedDetailItem> _detailItemsForSubcategory(
    List<SavedDetailItem> source,
    FoodCuisineItem subcategory,
  ) {
    final keys = {
      _normalizedGenreKey(subcategory.id),
      _normalizedGenreKey(subcategory.title),
    }..remove('');
    if (keys.isEmpty) {
      return const [];
    }

    return source.where((item) {
      final values = [
        item.subcategory,
        item.activityType,
        item.feature,
        item.category,
        item.venueName,
      ].map(_normalizedGenreKey).where((value) => value.isNotEmpty);
      return values.any((value) {
        return keys.any((key) => value == key || value.contains(key));
      });
    }).toList();
  }

  List<SavedDetailItem> foodCuisinePlacesForTitle(String cuisineTitle) {
    final cuisineKey = _normalizedGenreKey(cuisineTitle);
    if (cuisineKey.isEmpty) {
      return const [];
    }

    return _allFoodPlaces.where((place) {
      return _normalizedGenreKey(place.subcategory) == cuisineKey ||
          _normalizedGenreKey(place.category) == cuisineKey ||
          _normalizedGenreKey(place.feature) == cuisineKey;
    }).toList();
  }

  void updateTab(int index) {
    if (_selectedTabIndex == index) {
      return;
    }

    _selectedTabIndex = index;
    resetBrowsingFilters(notify: false);
    notifyListeners();
  }

  Future<bool> enableLocation() async {
    if (_isUpdatingLocation) {
      return _locationEnabled;
    }

    _isUpdatingLocation = true;
    _hasCheckedLocationPermission = true;
    _locationError = null;
    notifyListeners();

    try {
      final hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        _locationEnabled = false;
        _nearbyVenueIds = <String>{};
        _locationError = 'Location permission was not granted.';
        await _locationService.openAppSettings();
        return false;
      }

      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      _locationServiceEnabled = serviceEnabled;
      if (!serviceEnabled) {
        _locationEnabled = false;
        _nearbyVenueIds = <String>{};
        _locationError = 'Please turn on your phone location services.';
        await _locationService.openLocationSettings();
        return false;
      }

      final location = await _locationService.updateCurrentUserLocation();
      if (location == null) {
        _locationEnabled = false;
        _nearbyVenueIds = <String>{};
        _locationError = 'Location permission was not granted.';
        return false;
      }

      _locationEnabled = true;
      _userLocation = location;
      await _refreshNearbyVenueIds(location);
      return true;
    } catch (error) {
      _locationEnabled = false;
      _locationError = error.toString();
      return false;
    } finally {
      _isUpdatingLocation = false;
      notifyListeners();
    }
  }

  Future<void> initializeLocation() async {
    if (_hasCheckedLocationPermission || _isUpdatingLocation) {
      return;
    }

    _hasCheckedLocationPermission = true;
    _locationError = null;
    notifyListeners();

    _locationServiceEnabled = await _locationService.isLocationServiceEnabled();
    if (!_locationServiceEnabled) {
      _locationEnabled = false;
      _nearbyVenueIds = <String>{};
      notifyListeners();
      return;
    }

    final hasPermission = await _locationService.hasLocationPermission();
    if (!hasPermission) {
      _locationEnabled = false;
      _nearbyVenueIds = <String>{};
      notifyListeners();
      return;
    }

    await enableLocation();
  }

  Future<void> refreshLocationState() async {
    _hasCheckedLocationPermission = false;
    await initializeLocation();
  }

  /// Keeps the home state in sync with the live permission status: it picks the
  /// location up as soon as access is granted and drops it when it is revoked.
  void _handleLocationPermissionChanged() {
    final hasAccess = _locationPermissionController.hasLocationAccess;

    if (!hasAccess) {
      if (!_locationEnabled && _nearbyVenueIds.isEmpty) {
        return;
      }

      _locationEnabled = false;
      _nearbyVenueIds = <String>{};
      _locationServiceEnabled = _locationPermissionController.serviceEnabled;
      notifyListeners();
      return;
    }

    if (_locationEnabled || _isUpdatingLocation) {
      _locationServiceEnabled = true;
      return;
    }

    _locationServiceEnabled = true;
    unawaited(refreshLocationState());
  }

  void updateActivityFilter(String filter) {
    if (_selectedActivityFilter == filter) {
      return;
    }

    _selectedActivityFilter = filter;
    notifyListeners();
  }

  void updateMusicFilter(String filter) {
    if (_selectedMusicFilter == filter) {
      return;
    }

    _selectedMusicFilter = filter;
    notifyListeners();
  }

  void updateMusicSearchQuery(String value) {
    if (_musicSearchQuery == value) {
      return;
    }

    _musicSearchQuery = value;
    _trackSearch(value, category: AppStrings.music);
    notifyListeners();
  }

  void updateFoodFilter(String filter) {
    if (_selectedFoodFilter == filter) {
      return;
    }

    _selectedFoodFilter = filter;
    notifyListeners();
  }

  void updateFoodSearchQuery(String value, {bool notify = true}) {
    if (_foodSearchQuery == value) {
      return;
    }

    _foodSearchQuery = value;
    _trackSearch(value, category: AppStrings.foodDrink);
    if (notify) {
      notifyListeners();
    }
  }

  void updateEventFilter(String filter) {
    if (_selectedEventFilter == filter) {
      return;
    }

    _selectedEventFilter = filter;
    notifyListeners();
  }

  void updateEventSearchQuery(String value) {
    if (_eventSearchQuery == value) {
      return;
    }

    _eventSearchQuery = value;
    _trackSearch(value, category: AppStrings.events);
    notifyListeners();
  }

  void updateActivitySearchQuery(String value) {
    if (_activitySearchQuery == value) {
      return;
    }

    _activitySearchQuery = value;
    _trackSearch(value, category: AppStrings.activities);
    notifyListeners();
  }

  void updateHealthFilter(String filter) {
    if (_selectedHealthFilter == filter) {
      return;
    }

    _selectedHealthFilter = filter;
    notifyListeners();
  }

  void updateSavedFilter(String filter) {
    if (_selectedSavedFilter == filter) {
      return;
    }

    _selectedSavedFilter = filter;
    notifyListeners();
  }

  void updateSavedSearchQuery(String value) {
    if (_savedSearchQuery == value) {
      return;
    }

    _savedSearchQuery = value;
    _trackSearch(value);
    notifyListeners();
  }

  void updateHomeSearchQuery(String value) {
    if (_homeSearchQuery == value) {
      return;
    }

    _homeSearchQuery = value;
    _trackSearch(value);
    notifyListeners();
  }

  void updateHomeCategoryFilter(String filter) {
    if (_selectedHomeCategoryFilter == filter) {
      return;
    }

    _selectedHomeCategoryFilter = filter;
    notifyListeners();
  }

  void updateHomeDiscoveryFilter(String filter) {
    if (_selectedHomeDiscoveryFilter == filter) {
      return;
    }

    _selectedHomeDiscoveryFilter = filter;
    notifyListeners();
  }

  void resetHomeFilters() {
    final hadChanges =
        _homeSearchQuery.isNotEmpty ||
        _selectedHomeCategoryFilter != AppStrings.all ||
        _selectedHomeDiscoveryFilter != AppStrings.all;
    if (!hadChanges) {
      return;
    }

    _homeSearchQuery = '';
    _selectedHomeCategoryFilter = AppStrings.all;
    _selectedHomeDiscoveryFilter = AppStrings.all;
    notifyListeners();
  }

  void resetBrowsingFilters({bool notify = true}) {
    _homeSearchQuery = '';
    _musicSearchQuery = '';
    _eventSearchQuery = '';
    _activitySearchQuery = '';
    _foodSearchQuery = '';
    _savedSearchQuery = '';
    _healthSearchQuery = '';
    _networkingSearchQuery = '';
    _selectedActivityFilter = AppStrings.popular;
    _selectedMusicFilter = AppStrings.liveNow;
    _selectedFoodFilter = '';
    _selectedEventFilter = AppStrings.liveNow;
    _selectedHealthFilter = AppStrings.openNow;
    _selectedNetworkingFilter = AppStrings.openNow;
    _selectedSavedFilter = AppStrings.all;
    _selectedHomeCategoryFilter = AppStrings.all;
    _selectedHomeDiscoveryFilter = AppStrings.all;
    if (notify) {
      notifyListeners();
    }
  }

  void updateHealthSearchQuery(String value) {
    if (_healthSearchQuery == value) {
      return;
    }

    _healthSearchQuery = value;
    _trackSearch(value, category: AppStrings.healthWellbeing);
    notifyListeners();
  }

  void updateNetworkingFilter(String filter) {
    if (_selectedNetworkingFilter == filter) {
      return;
    }

    _selectedNetworkingFilter = filter;
    notifyListeners();
  }

  void updateNetworkingSearchQuery(String value) {
    if (_networkingSearchQuery == value) {
      return;
    }

    _networkingSearchQuery = value;
    _trackSearch(value, category: AppStrings.networking);
    notifyListeners();
  }

  bool isSavedItemLiked(String id) {
    return _likedSavedItems.contains(id);
  }

  /// Records a search once the query settles.
  ///
  /// The search fields change on every keystroke, so recording each change
  /// would write one activity document per character typed.
  void _trackSearch(String query, {String? category}) {
    _searchTrackingDebounce?.cancel();
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return;
    }

    _searchTrackingDebounce = Timer(const Duration(milliseconds: 900), () {
      _activityTracking.trackActivityInBackground(
        action: ActivityActions.search,
        item: trimmedQuery,
        category: category,
      );
    });
  }

  /// Records a save or unsave, naming the item the toggle belongs to.
  void _trackSaveActivity(String id, {required bool wasSaved}) {
    final details = _savedItemDetails(id);
    _activityTracking.trackActivityInBackground(
      action: wasSaved
          ? ActivityActions.itemUnsaved
          : ActivityActions.itemSaved,
      item: details?.title,
      category: details?.category,
      city: details?.city,
    );
  }

  /// Resolves the title, category and city behind a saveable id so the toggle
  /// call sites can keep passing an id on its own.
  ///
  /// The category is taken from the list the item belongs to, which keeps the
  /// recorded value the same as the one the category screens record.
  _SavedItemDetails? _savedItemDetails(String id) {
    final detailLists = <String, List<SavedDetailItem>>{
      AppStrings.activities: _allActivityItems,
      AppStrings.foodDrink: _allFoodPlaces,
      AppStrings.healthWellbeing: _allHealthItems,
      AppStrings.networking: _allNetworkingItems,
    };

    for (final entry in detailLists.entries) {
      for (final item in entry.value) {
        if (item.id == id) {
          return _SavedItemDetails(
            title: item.title,
            category: entry.key,
            city: item.city,
          );
        }
      }
    }

    final eventLists = <String, List<MusicEventItem>>{
      AppStrings.music: _allMusicEvents,
      AppStrings.events: _allEventItems,
    };

    for (final entry in eventLists.entries) {
      for (final event in entry.value) {
        if (event.id == id) {
          return _SavedItemDetails(
            title: event.title,
            category: entry.key,
            city: event.city,
          );
        }
      }
    }

    return null;
  }

  Future<void> toggleSavedItemLike(String id) async {
    if (_pendingSavedItemIds.contains(id)) {
      return;
    }

    final user = _firebaseAuth.currentUser;
    if (user == null) {
      await AccountAccessPrompt.show();
      return;
    }
    final wasLiked = _likedSavedItems.contains(id);

    _pendingSavedItemIds.add(id);
    if (wasLiked) {
      _likedSavedItems.remove(id);
    } else {
      _likedSavedItems.add(id);
    }
    _savedItemsError = null;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'savedItemIds': wasLiked
            ? FieldValue.arrayRemove([id])
            : FieldValue.arrayUnion([id]),
        'lastActive': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));
      _trackSaveActivity(id, wasSaved: wasLiked);
    } catch (error) {
      if (wasLiked) {
        _likedSavedItems.add(id);
      } else {
        _likedSavedItems.remove(id);
      }
      _savedItemsError = error.toString();
    } finally {
      _pendingSavedItemIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> loadSavedItems({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      _savedItemsLoadedForUid = null;
      _likedSavedItems.clear();
      _pendingSavedItemIds.clear();
      notifyListeners();
      return;
    }

    if (_isLoadingSavedItems ||
        (_savedItemsLoadedForUid == user.uid && !forceRefresh)) {
      return;
    }

    _isLoadingSavedItems = true;
    _savedItemsError = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      final data = snapshot.data();
      final savedItemIds = data?['savedItemIds'];
      _likedSavedItems
        ..clear()
        ..addAll(_stringList(savedItemIds));
      _savedItemsLoadedForUid = user.uid;
    } catch (error) {
      _savedItemsError = error.toString();
    } finally {
      _isLoadingSavedItems = false;
      notifyListeners();
    }
  }

  Future<void> loadUserTags({bool forceRefresh = false}) async {
    await loadPublicData(forceRefresh: forceRefresh);
  }

  void _handleAuthStateChanged(User? user) {
    unawaited(_userTagsSubscription?.cancel());
    _userTagsSubscription = null;
    _interestedTagKeys = <String>{};

    if (user == null) {
      _savedItemsLoadedForUid = null;
      _likedSavedItems.clear();
      _pendingSavedItemIds.clear();
      _locationEnabled = false;
      _hasCheckedLocationPermission = false;
      _userLocation = null;
      _nearbyVenueIds = <String>{};
      notifyListeners();
      return;
    }

    _userTagsSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snapshot) {
            _interestedTagKeys = _tagKeysFromUserData(snapshot.data());
            notifyListeners();
          },
          onError: (_) {
            _interestedTagKeys = <String>{};
            notifyListeners();
          },
        );
    unawaited(
      loadSavedItems(forceRefresh: _savedItemsLoadedForUid != user.uid),
    );
    unawaited(_loadSavedLocation(user.uid));
  }

  Future<void> _loadSavedLocation(String userId) async {
    try {
      final location = await _locationService.fetchSavedUserLocation(userId);
      if (location == null) {
        return;
      }

      _userLocation = location;
      _locationServiceEnabled = await _locationService
          .isLocationServiceEnabled();
      final hasPermission = await _locationService.hasLocationPermission();
      _locationEnabled = _locationServiceEnabled && hasPermission;
      if (_locationEnabled) {
        await _refreshNearbyVenueIds(location);
      } else {
        _nearbyVenueIds = <String>{};
      }
      notifyListeners();
    } catch (_) {
      // Saved location is best-effort; permission requests still handle errors.
    }
  }

  Future<void> _refreshNearbyVenueIds(UserLocation location) async {
    final venues = await _nearbyService.fetchNearbyVenues(
      userLocation: location,
    );
    _nearbyVenueIds = venues.map((venue) => venue.id).toSet();
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

  static Set<String> _tagKeysFromUserData(Map<String, dynamic>? data) {
    if (data == null) {
      return <String>{};
    }

    final tags = <String>{};

    void collect(Object? value) {
      if (value == null) {
        return;
      }

      if (value is Iterable) {
        for (final item in value) {
          collect(item);
        }
        return;
      }

      if (value is Map) {
        collect([
          value['tagName'],
          value['tag_name'],
          value['name'],
          value['title'],
          value['label'],
          value['value'],
          value['id'],
          value['tagId'],
          value['tag_id'],
        ]);
        return;
      }

      final tagKey = _normalizedGenreKey(value.toString());
      if (tagKey.isNotEmpty) {
        tags.add(tagKey);
      }
    }

    // `tags` is the single source of truth written by onboarding and profile
    // settings. Never merge legacy interest fields into recommendations: they
    // can contain stale/unselected values and leak unrelated content.
    collect(data['tags']);

    return tags.take(_maximumRecommendationInterestTags).toSet();
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_userTagsSubscription?.cancel());
    for (final subscription in _publicDataSubscriptions) {
      unawaited(subscription.cancel());
    }
    _publicRefreshDebounce?.cancel();
    _searchTrackingDebounce?.cancel();
    _locationPermissionController.removeListener(
      _handleLocationPermissionChanged,
    );
    super.dispose();
  }

  Future<void> recordCategoryView(String category) {
    return _logUserActivity(
      action: 'category_view',
      category: category,
    );
  }

  Future<void> recordAppOpen() {
    return _logUserActivity(
      action: 'app_open',
      category: 'App',
    );
  }

  Future<void> recordSearch({
    required String query,
    required String category,
  }) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return Future<void>.value();
    }

    return _logUserActivity(
      action: 'search',
      category: category,
      itemTitle: trimmedQuery,
      searchQuery: trimmedQuery,
    );
  }

  Future<void> recordListingView({
    required String category,
    required String itemId,
    required String itemTitle,
    String? subcategory,
  }) {
    return _logUserActivity(
      action: 'listing_view',
      category: category,
      itemId: itemId,
      itemTitle: itemTitle,
      subcategory: subcategory,
    );
  }

  Future<void> _logUserActivity({
    required String action,
    required String category,
    String? itemId,
    String? itemTitle,
    String? subcategory,
    String? searchQuery,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      final userData = userSnapshot.data() ?? const <String, dynamic>{};
      final userName =
          (userData['name'] ?? user.displayName ?? user.email ?? 'User')
              .toString()
              .trim();
      final city = (userData['city'] ?? userCity ?? '').toString().trim();
      final now = DateTime.now();
      final utcIso = now.toUtc().toIso8601String();

      await _firestore.collection('userActivity').add({
        'userId': user.uid,
        'uid': user.uid,
        'user': userName.isEmpty ? 'User' : userName,
        'userName': userName.isEmpty ? 'User' : userName,
        'email': user.email ?? '',
        'city': city,
        'category': category,
        'subcategory': subcategory ?? '',
        'action': action,
        'eventType': action,
        'itemId': itemId ?? '',
        'itemTitle': itemTitle ?? '',
        'listingId': itemId ?? '',
        'listingTitle': itemTitle ?? '',
        'searchQuery': searchQuery ?? '',
        'query': searchQuery ?? '',
        'time': utcIso,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtIso': utcIso,
        'date': now.day,
        'month': now.month,
        'year': now.year,
      });
    } catch (_) {
      // User activity must never block the app experience.
    }
  }

  String _categoryForSavedItem(String id) {
    for (final entry in <MapEntry<String, Iterable<dynamic>>>[
      MapEntry(AppStrings.music, _allMusicEvents),
      MapEntry(AppStrings.events, _allEventItems),
      MapEntry(AppStrings.activitiesAdventure, _allActivityItems),
      MapEntry(AppStrings.foodDrink, _allFoodPlaces),
      MapEntry(AppStrings.healthWellbeing, _allHealthItems),
      MapEntry(AppStrings.networking, _allNetworkingItems),
    ]) {
      if (entry.value.any((item) => item.id == id)) {
        return entry.key;
      }
    }

    return AppStrings.saved;
  }

  String _titleForSavedItem(String id) {
    for (final item in _allMusicEvents) {
      if (item.id == id) {
        return item.title;
      }
    }
    for (final item in _allEventItems) {
      if (item.id == id) {
        return item.title;
      }
    }
    for (final item in _allActivityItems) {
      if (item.id == id) {
        return item.title;
      }
    }
    for (final item in _allFoodPlaces) {
      if (item.id == id) {
        return item.title;
      }
    }
    for (final item in _allHealthItems) {
      if (item.id == id) {
        return item.title;
      }
    }
    for (final item in _allNetworkingItems) {
      if (item.id == id) {
        return item.title;
      }
    }

    return '';
  }
}

class _SavedItemDetails {
  const _SavedItemDetails({
    required this.title,
    required this.category,
    required this.city,
  });

  final String title;
  final String category;
  final String? city;
}

class HomeDiscoveryDestination {
  const HomeDiscoveryDestination({
    required this.routeName,
    required this.arguments,
  });

  final String routeName;
  final Object arguments;
}
