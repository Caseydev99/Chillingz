import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_strings.dart';
import '../../../routes/app_routes.dart';
import '../models/chillingz_content_item.dart';
import '../models/food_cuisine_item.dart';
import '../models/home_category_item.dart';
import '../models/home_discovery_item.dart';
import '../models/music_event_item.dart';
import '../models/music_genre_item.dart';
import '../models/saved_detail_item.dart';
import '../models/social_post_item.dart';

class HomeFirestoreData {
  const HomeFirestoreData({
    required this.categories,
    required this.discoveryItems,
    required this.discoveryFilters,
    required this.musicGenres,
    required this.musicEvents,
    required this.eventItems,
    required this.activityItems,
    required this.activitySubcategories,
    required this.foodCuisines,
    required this.foodPlaces,
    required this.healthSubcategories,
    required this.healthItems,
    required this.networkingSubcategories,
    required this.networkingItems,
    required this.activityFilters,
    required this.foodFilters,
    required this.eventFilters,
    required this.musicFilters,
    required this.healthFilters,
    required this.networkingFilters,
  });

  final List<HomeCategoryItem> categories;
  final List<HomeDiscoveryItem> discoveryItems;
  final List<String> discoveryFilters;
  final List<MusicGenreItem> musicGenres;
  final List<MusicEventItem> musicEvents;
  final List<MusicEventItem> eventItems;
  final List<SavedDetailItem> activityItems;
  final List<FoodCuisineItem> activitySubcategories;
  final List<FoodCuisineItem> foodCuisines;
  final List<SavedDetailItem> foodPlaces;
  final List<FoodCuisineItem> healthSubcategories;
  final List<SavedDetailItem> healthItems;
  final List<FoodCuisineItem> networkingSubcategories;
  final List<SavedDetailItem> networkingItems;
  final List<String> activityFilters;
  final List<String> foodFilters;
  final List<String> eventFilters;
  final List<String> musicFilters;
  final List<String> healthFilters;
  final List<String> networkingFilters;
}

class HomeFirestoreService {
  HomeFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<HomeFirestoreData> fetchPublicHomeData({
    Source source = Source.server,
  }) async {
    final options = GetOptions(source: source);
    final results = await Future.wait([
      _firestore.collection('categories').get(options),
      _firestore.collection('genres').get(options),
      _firestore.collection('subcategories').get(options),
      _firestore.collection('subcategoriesContent').get(options),
      _firestore.collection('listingCategories').get(options),
      _firestore.collection('tags').get(options),
    ]);

    final categories = _mapCategories(results[0].docs);
    final genreBundle = _mapGenres(results[1].docs);
    final subcategoryBundle = _mapSubcategories(results[2].docs);
    final contentBundle = _mapContent(results[3].docs);
    final listingBundle = _mapListings(results[4].docs);
    final discoveryItems = _mapChillingz(
      genreDocs: results[1].docs,
      contentDocs: results[3].docs,
      listingDocs: results[4].docs,
      tagsDocs: results[5].docs,
    );
    final discoveryFilters = _mapDiscoveryFilters(
      tagsDocs: results[5].docs,
      discoveryItems: discoveryItems,
    );

    final musicEvents = [
      ...genreBundle.musicEvents,
      ...contentBundle.musicEvents,
      ...listingBundle.musicEvents,
    ];
    final eventItems = [
      ...genreBundle.eventItems,
      ...contentBundle.eventItems,
      ...listingBundle.eventItems,
    ];
    final activityItems = [
      ...contentBundle.activityItems,
      ...listingBundle.activityItems,
    ];
    final foodPlaces = [
      ...contentBundle.foodPlaces,
      ...listingBundle.foodPlaces,
    ];
    final healthItems = [
      ...contentBundle.healthItems,
      ...listingBundle.healthItems,
    ];
    final networkingItems = [
      ...contentBundle.networkingItems,
      ...listingBundle.networkingItems,
    ];

    return HomeFirestoreData(
      categories: categories,
      discoveryItems: discoveryItems,
      discoveryFilters: discoveryFilters,
      musicGenres: _uniqueMusicGenres([
        ...subcategoryBundle.musicGenres,
        ...genreBundle.genres,
      ]),
      musicEvents: musicEvents,
      eventItems: eventItems,
      activityItems: activityItems,
      activitySubcategories: subcategoryBundle.activitySubcategories,
      foodCuisines: subcategoryBundle.foodCuisines,
      foodPlaces: foodPlaces,
      healthSubcategories: subcategoryBundle.healthSubcategories,
      healthItems: healthItems,
      networkingSubcategories: subcategoryBundle.networkingSubcategories,
      networkingItems: networkingItems,
      activityFilters: _mergeFilters([
        ...subcategoryBundle.activityFilters,
        ..._filtersFromDetails(activityItems),
      ]),
      foodFilters: _mergeFilters([
        ...subcategoryBundle.foodFilters,
        ..._filtersFromDetails(foodPlaces),
      ]),
      eventFilters: _mergeFilters([
        ...subcategoryBundle.eventFilters,
        ..._filtersFromMusicEvents(eventItems),
      ]),
      musicFilters: _mergeFilters([
        ...subcategoryBundle.musicFilters,
        ..._filtersFromMusicEvents(musicEvents),
      ]),
      healthFilters: _mergeFilters([
        ...subcategoryBundle.healthFilters,
        ..._filtersFromDetails(healthItems),
      ]),
      networkingFilters: _mergeFilters([
        ...subcategoryBundle.networkingFilters,
        ..._filtersFromDetails(networkingItems),
      ]),
    );
  }

  static List<HomeCategoryItem> _mapCategories(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final items = docs
        .map((doc) {
          final data = doc.data();
          if (!_isActive(data)) {
            return null;
          }

          final slug = _text(
            data['slug'],
          ).ifEmpty(_text(data['id'])).ifEmpty(doc.id);
          final title = _text(data['name']).ifEmpty(slug);
          return HomeCategoryItem(
            id: slug,
            title: title,
            imagePath: _imageUrl(data),
            icon: _categoryIcon(slug, _text(data['icon'])),
            darkOverlay: true,
            routeName: _categoryRoute(slug, title),
          );
        })
        .whereType<HomeCategoryItem>()
        .toList();

    items.sort((a, b) => a.title.compareTo(b.title));
    return items;
  }

  static _GenreBundle _mapGenres(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final genres = <MusicGenreItem>[];
    final musicEvents = <MusicEventItem>[];
    final eventItems = <MusicEventItem>[];

    for (final doc in docs) {
      final data = doc.data();
      final posts = _map(data['posts']);
      final events = _map(data['events']);
      if (!_isActive(data) || !_isActive(posts, defaultValue: true)) {
        continue;
      }

      final genreTitle = _labelFrom([
        posts['singerName'],
        posts['name'],
        posts['title'],
        events['name'],
        events['title'],
        data['name'],
        data['title'],
        data['displayName'],
        posts['slug'],
        events['slug'],
        data['slug'],
        _displayableDocumentId(doc.id),
      ]);
      final image = _imageUrl(events).ifEmpty(_imageUrl(data, posts));
      final venueName = _venueName(data, posts, events);
      final subcategory = _musicGenreFrom(data, posts);

      if (genreTitle.isNotEmpty) {
        genres.add(
          MusicGenreItem(id: doc.id, title: genreTitle, imagePath: image),
        );
      }

      final item = MusicEventItem(
        id: doc.id,
        title: _labelFrom([
          events['name'],
          events['title'],
          genreTitle,
          _displayableDocumentId(doc.id),
        ]).ifEmpty(AppStrings.music),
        location: venueName.ifEmpty(_text(events['location'])),
        imagePath: image,
        badgeText: _dateBadge(
          events['date'] ?? data['date'] ?? events['eventDate'],
        ),
        rating: _rating(data['avg_rating']),
        priceLabel: _priceLabel(
          _priceValue(data, posts),
          _currency(data, posts),
        ),
        genre: subcategory.ifEmpty(genreTitle),
        feature: _featureLabel(data, posts, events),
        subcategory: subcategory,
        headliner: _headliner(data, posts, events).ifEmpty(genreTitle),
        venueName: venueName,
        timeLabel: _timeLabel(data, posts, events),
        websiteLink: _links(data, posts, events).website,
        mapLink: _links(data, posts, events).map,
        ticketLink: _links(data, posts, events).ticket,
        city: _venueCity(data, posts, events),
        latitude: _venueLatitude(data, posts, events),
        longitude: _venueLongitude(data, posts, events),
        socialPosts: _socialPostsFrom(data, fallbackImage: image),
      );

      final feature = _text(events['feature']).toLowerCase();
      if (feature.contains('feature') ||
          _text(data['category_id']).contains('music')) {
        musicEvents.add(item);
      } else {
        eventItems.add(item);
      }
    }

    return _GenreBundle(
      genres: genres,
      musicEvents: musicEvents,
      eventItems: eventItems,
    );
  }

  static _SubcategoryBundle _mapSubcategories(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final foodCuisines = <FoodCuisineItem>[];
    final activitySubcategories = <FoodCuisineItem>[];
    final healthSubcategories = <FoodCuisineItem>[];
    final networkingSubcategories = <FoodCuisineItem>[];
    final musicGenres = <MusicGenreItem>[];
    final activityFilters = <String>{};
    final foodFilters = <String>{};
    final eventFilters = <String>{};
    final musicFilters = <String>{};
    final healthFilters = <String>{};
    final networkingFilters = <String>{};

    for (final doc in docs) {
      final data = doc.data();
      if (!_isActive(data)) {
        continue;
      }

      final parent = _parentCategoryLabel(data).toLowerCase();
      final title = _canonicalSubcategoryLabel(
        _labelFrom([
          data['subcategoryName'],
          data['subcategory_name'],
          data['subCategoryName'],
          data['name'],
          data['title'],
          data['displayName'],
          data['slug'],
          _displayableDocumentId(doc.id),
        ]),
      );
      if (title.isEmpty || _isInvalidSubcategoryLabel(title)) {
        continue;
      }

      final feature = _featureLabel(data);
      final subcategoryItem = FoodCuisineItem(
        id: _text(data['slug']).ifEmpty(doc.id),
        title: title,
        imagePath: _imageUrl(data),
      );
      final bucket = _bucketFromText(parent);
      switch (bucket) {
        case _ContentBucket.activities:
          activitySubcategories.add(subcategoryItem);
          activityFilters.add(title);
          if (feature.isNotEmpty) {
            activityFilters.add(feature);
          }
          break;
        case _ContentBucket.food:
          foodFilters.add(title);
          if (feature.isNotEmpty) {
            foodFilters.add(feature);
          }
          break;
        case _ContentBucket.health:
          healthSubcategories.add(subcategoryItem);
          healthFilters.add(title);
          if (feature.isNotEmpty) {
            healthFilters.add(feature);
          }
          break;
        case _ContentBucket.networking:
          networkingSubcategories.add(subcategoryItem);
          networkingFilters.add(title);
          if (feature.isNotEmpty) {
            networkingFilters.add(feature);
          }
          break;
        case _ContentBucket.events:
          eventFilters.add(title);
          if (feature.isNotEmpty) {
            eventFilters.add(feature);
          }
          break;
        case _ContentBucket.music:
          musicFilters.add(title);
          if (feature.isNotEmpty) {
            musicFilters.add(feature);
          }
          break;
      }

      if (parent.contains('food') || parent.contains('drink')) {
        foodCuisines.add(subcategoryItem);
        continue;
      }

      if (parent.contains('music')) {
        musicGenres.add(
          MusicGenreItem(
            id: _text(data['slug']).ifEmpty(doc.id),
            title: title,
            imagePath: _imageUrl(data),
          ),
        );
      }
    }

    return _SubcategoryBundle(
      foodCuisines: _uniqueFoodCuisineItems(foodCuisines),
      activitySubcategories: _uniqueFoodCuisineItems(activitySubcategories),
      healthSubcategories: _uniqueFoodCuisineItems(healthSubcategories),
      networkingSubcategories: _uniqueFoodCuisineItems(networkingSubcategories),
      musicGenres: musicGenres,
      activityFilters: _sortedFilters(activityFilters),
      foodFilters: _sortedFilters(foodFilters),
      eventFilters: _sortedFilters(eventFilters),
      musicFilters: _sortedFilters(musicFilters),
      healthFilters: _sortedFilters(healthFilters),
      networkingFilters: _sortedFilters(networkingFilters),
    );
  }

  static _ContentBundle _mapContent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final activities = <SavedDetailItem>[];
    final food = <SavedDetailItem>[];
    final health = <SavedDetailItem>[];
    final networking = <SavedDetailItem>[];
    final events = <MusicEventItem>[];
    final music = <MusicEventItem>[];

    for (final doc in docs) {
      final data = doc.data();
      if (!_isActive(data)) {
        continue;
      }

      final bucket = _contentBucket(data);
      final title = _labelFrom([
        data['singerName'],
        data['artistName'],
        data['userName'],
        data['name'],
        data['title'],
        data['description'],
        data['slug'],
        _displayableDocumentId(doc.id),
      ]);
      if (title.isEmpty) {
        continue;
      }
      final category = _text(data['activity_type'])
          .ifEmpty(_text(data['category_name']))
          .ifEmpty(_text(data['content_type']))
          .ifEmpty(_parentCategoryLabel(data));
      final image = _imageUrl(data);
      final links = _links(data);
      final venueName = _venueName(data);
      final subcategory = _subcategoryLabel(data);
      final activityType = _activityType(data);

      if (bucket == _ContentBucket.events || bucket == _ContentBucket.music) {
        final item = MusicEventItem(
          id: doc.id,
          title: title,
          location: venueName
              .ifEmpty(_text(data['location']))
              .ifEmpty(category),
          imagePath: image,
          badgeText: _dateBadge(
            data['date'] ?? data['available_from'] ?? data['eventDate'],
          ),
          rating: _rating(data['review'] ?? data['avg_rating']),
          priceLabel: _priceLabel(_priceValue(data), _currency(data)),
          genre: _musicGenreFrom(data).ifEmpty(subcategory),
          feature: _featureLabel(data),
          subcategory: subcategory,
          headliner: _headliner(data),
          venueName: venueName,
          timeLabel: _timeLabel(data),
          websiteLink: links.website,
          mapLink: links.map,
          ticketLink: links.ticket,
          city: _venueCity(data),
          latitude: _venueLatitude(data),
          longitude: _venueLongitude(data),
          socialPosts: _socialPostsFrom(data, fallbackImage: image),
        );
        if (bucket == _ContentBucket.music) {
          music.add(item);
        } else {
          events.add(item);
        }
        continue;
      }

      final item = SavedDetailItem(
        id: doc.id,
        title: title,
        category: category,
        imagePath: image,
        backgroundColor: _backgroundColor(bucket),
        priceLabel: _priceLabel(_priceValue(data), _currency(data)),
        distance: _text(data['distance']),
        rating: _rating(data['review'] ?? data['avg_rating']),
        feature: _featureLabel(data),
        city: _venueCity(data),
        latitude: _venueLatitude(data),
        longitude: _venueLongitude(data),
        venueName: venueName,
        parentCategory: _parentCategoryLabel(data),
        subcategory: subcategory,
        activityType: activityType,
        websiteLink: links.website,
        mapLink: links.map,
        ticketLink: links.ticket,
        socialPosts: _socialPostsFrom(data, fallbackImage: image),
      );

      switch (bucket) {
        case _ContentBucket.activities:
          activities.add(item);
          break;
        case _ContentBucket.food:
          food.add(item);
          break;
        case _ContentBucket.health:
          health.add(item);
          break;
        case _ContentBucket.networking:
          networking.add(item);
          break;
        case _ContentBucket.events:
        case _ContentBucket.music:
          break;
      }
    }

    return _ContentBundle(
      activityItems: activities,
      foodPlaces: food,
      healthItems: health,
      networkingItems: networking,
      eventItems: events,
      musicEvents: music,
    );
  }

  static _ContentBundle _mapListings(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final activities = <SavedDetailItem>[];
    final food = <SavedDetailItem>[];
    final health = <SavedDetailItem>[];
    final networking = <SavedDetailItem>[];
    final events = <MusicEventItem>[];
    final music = <MusicEventItem>[];

    for (final doc in docs) {
      final data = doc.data();
      final posts = _map(data['posts']);
      if (!_isActive(data) || !_isActive(posts, defaultValue: true)) {
        continue;
      }

      final bucket = _listingBucket(data);
      final title = _labelFrom([
        posts['title'],
        posts['name'],
        data['title'],
        data['name'],
        data['listingName'],
        data['slug'],
        _displayableDocumentId(doc.id),
      ]);
      if (title.isEmpty) {
        continue;
      }
      final listingName = _labelFrom([
        data['listingName'],
        data['categoryName'],
      ]);
      final image = _imageUrl(data, posts);
      final location = _listingLocation(data).ifEmpty(listingName);
      final links = _links(data, posts);
      final venueName = _venueName(data, posts);
      final subcategory = _subcategoryLabel(data, posts);
      final activityType = _activityType(data, posts);
      final price = _priceLabel(
        _priceValue(data, posts),
        _currency(data, posts),
      );
      final rating = _rating(
        posts['review'] ?? posts['rating'] ?? data['review'] ?? data['rating'],
      );

      if (bucket == _ContentBucket.events || bucket == _ContentBucket.music) {
        final item = MusicEventItem(
          id: doc.id,
          title: title,
          location: venueName.ifEmpty(location),
          imagePath: image,
          badgeText: _dateBadge(
            data['date'] ??
                data['eventDate'] ??
                posts['date'] ??
                posts['eventDate'],
          ),
          rating: rating,
          priceLabel: price,
          genre: _musicGenreFrom(data, posts).ifEmpty(subcategory),
          feature: _featureLabel(data, posts),
          subcategory: subcategory,
          headliner: _headliner(data, posts),
          venueName: venueName,
          timeLabel: _timeLabel(data, posts),
          websiteLink: links.website,
          mapLink: links.map,
          ticketLink: links.ticket,
          city: _venueCity(data, posts),
          latitude: _venueLatitude(data, posts),
          longitude: _venueLongitude(data, posts),
          socialPosts: _socialPostsFrom(data, fallbackImage: image),
        );
        if (bucket == _ContentBucket.music) {
          music.add(item);
        } else {
          events.add(item);
        }
        continue;
      }

      final item = SavedDetailItem(
        id: doc.id,
        title: title,
        category: listingName,
        imagePath: image,
        backgroundColor: _backgroundColor(bucket),
        priceLabel: price,
        distance: _text(data['distance']),
        rating: rating,
        feature: _featureLabel(data, posts),
        city: _venueCity(data, posts),
        latitude: _venueLatitude(data, posts),
        longitude: _venueLongitude(data, posts),
        venueName: venueName,
        parentCategory: _parentCategoryLabel(data, posts),
        subcategory: subcategory,
        activityType: activityType,
        websiteLink: links.website,
        mapLink: links.map,
        ticketLink: links.ticket,
        socialPosts: _socialPostsFrom(data, fallbackImage: image),
      );

      switch (bucket) {
        case _ContentBucket.activities:
          activities.add(item);
          break;
        case _ContentBucket.food:
          food.add(item);
          break;
        case _ContentBucket.health:
          health.add(item);
          break;
        case _ContentBucket.networking:
          networking.add(item);
          break;
        case _ContentBucket.events:
        case _ContentBucket.music:
          break;
      }
    }

    return _ContentBundle(
      activityItems: activities,
      foodPlaces: food,
      healthItems: health,
      networkingItems: networking,
      eventItems: events,
      musicEvents: music,
    );
  }

  static List<HomeDiscoveryItem> _mapChillingz({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> genreDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> contentDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> listingDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> tagsDocs,
  }) {
    final items = <HomeDiscoveryItem>[];
    final activeTags = <String, String>{};

    for (final doc in tagsDocs) {
      final data = doc.data();
      if (!_isActive(data)) {
        continue;
      }
      final label = _labelFrom([
        data['tagName'],
        data['name'],
        data['title'],
        data['slug'],
        _displayableDocumentId(doc.id),
      ]);
      if (label.isEmpty) {
        continue;
      }
      final keys = <String>{
        _lookupKey(doc.id),
        _lookupKey(label),
        _lookupKey(data['id']),
        _lookupKey(data['name']),
        _lookupKey(data['slug']),
      }..remove('');
      for (final key in keys) {
        activeTags[key] = label;
      }
    }

    void addDocuments(
      String source,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    ) {
      for (final doc in docs) {
        final data = doc.data();
        final posts = _map(data['posts']);
        final events = _map(data['events']);
        if (!_isActive(data) || !_isActive(posts, defaultValue: true)) {
          continue;
        }

        final rawTags = _tagLabels([
          data['tag'],
          data['tags'],
          data['tagName'],
          data['tagNames'],
          data['interestTags'],
          data['interestedTags'],
          posts['tag'],
          posts['tags'],
          posts['tagName'],
          posts['tagNames'],
          events['tag'],
          events['tags'],
          events['tagName'],
          events['tagNames'],
        ]);
        final tags = rawTags
            .map((tag) => activeTags[_lookupKey(tag)])
            .whereType<String>()
            .toSet()
            .toList();
        // A deleted or unassigned tag must never keep content in For You.
        if (tags.isEmpty) {
          continue;
        }

        final content = _chillingzContentFromData(data, '$source:${doc.id}');
        if (content == null) {
          continue;
        }
        final taggedContent = ChillingzContentItem(
          id: content.id,
          title: content.title,
          description: content.description,
          imagePath: content.imagePath,
          priceLabel: content.priceLabel,
          rating: content.rating,
          status: content.status,
          websiteLink: content.websiteLink,
          mapLink: content.mapLink,
          ticketLink: content.ticketLink,
          venueName: content.venueName,
          tags: tags,
          socialPosts: content.socialPosts,
        );
        items.add(
          HomeDiscoveryItem(
            id: taggedContent.id,
            title: taggedContent.title,
            imagePath: taggedContent.imagePath,
            tag: tags.first,
            tags: tags,
            isNature: _isNatureDiscovery(taggedContent.title, tags.first),
            contentItems: <ChillingzContentItem>[taggedContent],
          ),
        );
      }
    }

    addDocuments('music', genreDocs);
    addDocuments('content', contentDocs);
    addDocuments('listing', listingDocs);
    return items;
  }

  static ChillingzContentItem? _chillingzContentFromData(
    Map<String, dynamic> data,
    String id,
  ) {
    final posts = _map(data['posts']);
    final events = _map(data['events']);
    final image = _imageUrl(events).ifEmpty(_imageUrl(data, posts));
    final links = _links(data, posts, events);
    final websiteLink = links.website.ifEmpty(
      _firstText([data['url'], posts['url']]),
    );
    final title = _labelFrom([
      posts['title'],
      events['name'],
      events['title'],
      data['title'],
      data['name'],
      posts['name'],
      posts['singerName'],
      posts['artistName'],
      data['singerName'],
      data['artistName'],
      data['userName'],
    ]);
    final sourceSeparator = id.indexOf(':');
    final documentId = sourceSeparator < 0
        ? id
        : id.substring(sourceSeparator + 1);
    final titleIsDocumentId =
        _lookupKey(title).isNotEmpty &&
        _lookupKey(title) == _lookupKey(documentId);
    if (title.isEmpty || titleIsDocumentId) {
      return null;
    }

    final price = _priceValue(data, posts, events);
    final review =
        posts['review'] ??
        events['review'] ??
        data['review'] ??
        data['avg_rating'];
    final priceLabel = _text(price).isEmpty
        ? ''
        : _priceLabel(price, _currency(data, posts, events));
    final rating = _text(review).isEmpty ? '' : _rating(review);
    final status = _labelFrom([posts['status'], data['status']]);
    final tags = _tagLabels([
      data['tag'],
      data['tags'],
      data['tagName'],
      data['tagNames'],
      data['interestTags'],
      data['interestedTags'],
      posts['tag'],
      posts['tags'],
      posts['tagName'],
      posts['tagNames'],
      events['tag'],
      events['tags'],
      events['tagName'],
      events['tagNames'],
    ]);
    final venueName = _labelFrom([
      data['venue'],
      data['venueName'],
      data['venue_name'],
      posts['venue'],
      posts['venueName'],
      posts['venue_name'],
      events['venue'],
      events['venueName'],
      events['venue_name'],
    ]);
    final description = _firstText([
      data['description'],
      posts['description'],
      posts['caption'],
      events['description'],
      events['caption'],
    ]);
    final socialPosts = _socialPostsFrom(data, fallbackImage: image);
    return ChillingzContentItem(
      id: id,
      title: title,
      description: description,
      imagePath: image,
      priceLabel: priceLabel,
      rating: rating,
      status: status,
      websiteLink: websiteLink,
      mapLink: links.map,
      ticketLink: links.ticket,
      venueName: venueName,
      tags: tags,
      socialPosts: socialPosts,
    );
  }

  static List<String> _mapDiscoveryFilters({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> tagsDocs,
    required List<HomeDiscoveryItem> discoveryItems,
  }) {
    final filters = <String>{};

    for (final doc in tagsDocs) {
      final data = doc.data();
      if (!_isActive(data)) {
        continue;
      }

      final label = _labelFrom([
        data['tagName'],
        data['name'],
        data['title'],
        data['slug'],
        _displayableDocumentId(doc.id),
      ]);
      if (label.isNotEmpty) {
        filters.add(label);
      }
    }

    for (final item in discoveryItems) {
      for (final tag in <String>{item.tag, ...item.tags}) {
        if (tag.isNotEmpty) {
          filters.add(tag);
        }
      }
    }

    final sortedFilters = filters.toList()..sort((a, b) => a.compareTo(b));
    return [AppStrings.all, ...sortedFilters];
  }

  static _ContentBucket _contentBucket(Map<String, dynamic> data) {
    final value = [
      _text(data['content_type']),
      _text(data['category_id']),
      _text(data['category_name']),
      _text(data['parentCategory']),
    ].join(' ').toLowerCase();

    return _bucketFromText(value);
  }

  static _ContentBucket _bucketFromText(String value) {
    if (value.contains('food') || value.contains('drink')) {
      return _ContentBucket.food;
    }
    if (value.contains('health') || value.contains('wellbeing')) {
      return _ContentBucket.health;
    }
    if (value.contains('network')) {
      return _ContentBucket.networking;
    }
    if (value.contains('music')) {
      return _ContentBucket.music;
    }
    if (value.contains('event')) {
      return _ContentBucket.events;
    }
    return _ContentBucket.activities;
  }

  static _ContentBucket _listingBucket(Map<String, dynamic> data) {
    final value = [
      _text(data['categoryName']),
      _text(data['categoryId']),
      _text(data['listingName']),
    ].join(' ').toLowerCase();

    if (value.contains('food') || value.contains('drink')) {
      return _ContentBucket.food;
    }
    if (value.contains('health') || value.contains('wellbeing')) {
      return _ContentBucket.health;
    }
    if (value.contains('network')) {
      return _ContentBucket.networking;
    }
    if (value.contains('music')) {
      return _ContentBucket.music;
    }
    if (value.contains('event')) {
      return _ContentBucket.events;
    }
    return _ContentBucket.activities;
  }

  static bool _isActive(Map<String, dynamic> data, {bool defaultValue = true}) {
    final status = _text(data['status']).toLowerCase();
    if (status.isNotEmpty) {
      return status == 'active';
    }

    final isActive = data['is_active'];
    return isActive is bool ? isActive : defaultValue;
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is List && value.isNotEmpty) {
      return _map(value.first);
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static List<Map<String, dynamic>> _maps(Object? value) {
    if (value is Iterable) {
      return value.map(_map).where((item) => item.isNotEmpty).toList();
    }

    final map = _map(value);
    return map.isEmpty ? const [] : [map];
  }

  static String _text(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  static String _labelFrom(List<Object?> values) {
    for (final value in values) {
      final text = _text(value);
      if (text.isNotEmpty) {
        return _humanizedLabel(text);
      }
    }
    return '';
  }

  static String _displayableDocumentId(String id) {
    final looksGenerated = RegExp(r'^[A-Za-z0-9]{16,}$').hasMatch(id);
    return looksGenerated ? '' : id;
  }

  static String _humanizedLabel(String value) {
    final text = value.replaceAll(RegExp(r'[-_]+'), ' ').trim();
    if (text.isEmpty) {
      return '';
    }

    return text
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.length <= 2 && word == word.toUpperCase()) {
            return word;
          }
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  static String _listingLocation(Map<String, dynamic> data) {
    final location = _text(data['location']);
    if (location.isNotEmpty) {
      return location;
    }

    final latitude = _text(data['latitude']);
    final longitude = _text(data['longitude']);
    if (latitude.isNotEmpty && longitude.isNotEmpty) {
      return '$latitude, $longitude';
    }

    return '';
  }

  static String _venueCity(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
    Map<String, dynamic> events = const {},
  ]) {
    return _firstText([
      data['city'],
      _map(data['venue'])['city'],
      _map(data['location'])['city'],
      posts['city'],
      events['city'],
    ]);
  }

  static double? _venueLatitude(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
    Map<String, dynamic> events = const {},
  ]) {
    return _firstNumber([
      data['latitude'],
      data['lat'],
      _map(data['venue'])['latitude'],
      _map(data['venue'])['lat'],
      _map(data['location'])['latitude'],
      _map(data['location'])['lat'],
      posts['latitude'],
      posts['lat'],
      events['latitude'],
      events['lat'],
    ]);
  }

  static double? _venueLongitude(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
    Map<String, dynamic> events = const {},
  ]) {
    return _firstNumber([
      data['longitude'],
      data['lng'],
      data['lon'],
      _map(data['venue'])['longitude'],
      _map(data['venue'])['lng'],
      _map(data['venue'])['lon'],
      _map(data['location'])['longitude'],
      _map(data['location'])['lng'],
      _map(data['location'])['lon'],
      posts['longitude'],
      posts['lng'],
      posts['lon'],
      events['longitude'],
      events['lng'],
      events['lon'],
    ]);
  }

  static String _firstText(List<Object?> values) {
    for (final value in values) {
      final text = _text(value);
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static double? _firstNumber(List<Object?> values) {
    for (final value in values) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final number = double.tryParse(value.trim());
        if (number != null) {
          return number;
        }
      }
    }
    return null;
  }

  static String _imageUrl(
    Map<String, dynamic> data, [
    Map<String, dynamic> fallback = const {},
  ]) {
    return _firstText([
      data['imageUrl'],
      data['image_url'],
      data['imageURL'],
      data['image'],
      data['coverImageUrl'],
      data['cover_image_url'],
      data['coverImage'],
      data['cover_image'],
      data['bannerUrl'],
      data['banner_url'],
      data['posterUrl'],
      data['poster_url'],
      data['logoUrl'],
      data['logo_url'],
      data['photoUrl'],
      data['photo_url'],
      data['thumbnailUrl'],
      data['thumbnail_url'],
      data['thumbnail'],
      fallback['imageUrl'],
      fallback['image_url'],
      fallback['imageURL'],
      fallback['image'],
      fallback['coverImageUrl'],
      fallback['cover_image_url'],
      fallback['coverImage'],
      fallback['cover_image'],
      fallback['bannerUrl'],
      fallback['banner_url'],
      fallback['posterUrl'],
      fallback['poster_url'],
      fallback['logoUrl'],
      fallback['logo_url'],
      fallback['photoUrl'],
      fallback['photo_url'],
      fallback['thumbnailUrl'],
      fallback['thumbnail_url'],
      fallback['thumbnail'],
    ]);
  }

  static String _lookupKey(Object? value) {
    return _text(value).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static String _musicGenreFrom(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
  ]) {
    final label = _labelFrom([
      _firstFromIterable(data['subcategory_names']),
      _firstFromIterable(data['subcategories']),
      _firstFromIterable(data['genres']),
      data['genreName'],
      data['genre'],
      data['musicGenre'],
      data['subcategoryName'],
      data['subCategoryName'],
      data['subcategory'],
      data['subCategory'],
      data['parentSubcategory'],
      posts['genreName'],
      posts['genre'],
      posts['musicGenre'],
      posts['subcategoryName'],
      posts['subCategoryName'],
      posts['subcategory'],
      posts['subCategory'],
      posts['parentSubcategory'],
    ]);
    final canonicalLabel = _canonicalSubcategoryLabel(label);
    return _isInvalidSubcategoryLabel(canonicalLabel) ? '' : canonicalLabel;
  }

  static String _subcategoryLabel(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
  ]) {
    final label = _labelFrom([
      _firstFromIterable(data['subcategory_names']),
      _firstFromIterable(data['subcategories']),
      _firstFromIterable(data['subcategoryIds']),
      _firstFromIterable(data['subcategory_ids']),
      data['subcategoryName'],
      data['subCategoryName'],
      data['subcategory'],
      data['subCategory'],
      data['parentSubcategory'],
      posts['subcategoryName'],
      posts['subCategoryName'],
      posts['subcategory'],
      posts['subCategory'],
      posts['parentSubcategory'],
    ]);
    final canonicalLabel = _canonicalSubcategoryLabel(label);
    return _isInvalidSubcategoryLabel(canonicalLabel) ? '' : canonicalLabel;
  }

  static bool _isInvalidSubcategoryLabel(String value) {
    final label = value.trim();
    return label == '111' || label == '1111';
  }

  static String _canonicalSubcategoryLabel(String value) {
    final normalized = _lookupKey(value);
    if (normalized == 'panasian' || normalized == 'asianpanasian') {
      return 'Pan Asian';
    }
    return value;
  }

  static String _parentCategoryLabel(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
  ]) {
    return _labelFrom([
      data['parentCategory'],
      data['category_name'],
      data['categoryName'],
      data['category'],
      data['category_id'],
      data['categoryId'],
      data['content_type'],
      posts['parentCategory'],
      posts['category_name'],
      posts['categoryName'],
      posts['category'],
    ]);
  }

  static String _activityType(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
  ]) {
    return _labelFrom([
      data['activity_type'],
      data['activityType'],
      data['type'],
      data['venueType'],
      posts['activity_type'],
      posts['activityType'],
      posts['type'],
      posts['venueType'],
    ]);
  }

  static String _venueName(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
    Map<String, dynamic> events = const {},
  ]) {
    return _labelFrom([
      data['venueName'],
      data['venue_name'],
      _map(data['venue'])['name'],
      _map(data['venue'])['title'],
      _map(data['location'])['name'],
      posts['venueName'],
      posts['venue_name'],
      _map(posts['venue'])['name'],
      events['venueName'],
      events['venue_name'],
      _map(events['venue'])['name'],
    ]);
  }

  static String _headliner(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
    Map<String, dynamic> events = const {},
  ]) {
    return _labelFrom([
      data['singerName'],
      data['headliner'],
      data['artistName'],
      data['artist'],
      posts['singerName'],
      posts['headliner'],
      posts['artistName'],
      posts['artist'],
      events['singerName'],
      events['headliner'],
      events['artistName'],
      events['artist'],
    ]);
  }

  static String _timeLabel(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
    Map<String, dynamic> events = const {},
  ]) {
    return _firstText([
      data['time'],
      data['eventTime'],
      data['startTime'],
      data['available_time'],
      posts['time'],
      posts['eventTime'],
      posts['startTime'],
      events['time'],
      events['eventTime'],
      events['startTime'],
    ]);
  }

  static _LinkBundle _links(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
    Map<String, dynamic> events = const {},
  ]) {
    final linkMaps = [
      ..._maps(data['links']),
      ..._maps(posts['links']),
      ..._maps(events['links']),
    ];
    final websiteFromLinks = _linkByKind(linkMaps, _LinkKind.website);
    final mapFromLinks = _linkByKind(linkMaps, _LinkKind.map);
    final ticketFromLinks = _linkByKind(linkMaps, _LinkKind.ticket);
    final directDataUrl = _text(data['url']);
    final directPostsUrl = _text(posts['url']);
    final directEventsUrl = _text(events['url']);
    final directWebsite = _firstDirectLinkByKind([
      directDataUrl,
      directPostsUrl,
      directEventsUrl,
    ], _LinkKind.website);
    final directMap = _firstDirectLinkByKind([
      directDataUrl,
      directPostsUrl,
      directEventsUrl,
    ], _LinkKind.map);
    final directTicket = _firstDirectLinkByKind([
      directDataUrl,
      directPostsUrl,
      directEventsUrl,
    ], _LinkKind.ticket);

    return _LinkBundle(
      website: _firstText([
        websiteFromLinks,
        data['websiteLink'],
        data['websiteUrl'],
        data['website'],
        posts['websiteLink'],
        posts['websiteUrl'],
        posts['website'],
        events['websiteLink'],
        events['websiteUrl'],
        events['website'],
        directWebsite,
      ]),
      map: _firstText([
        mapFromLinks,
        data['mapLink'],
        data['googleMapLink'],
        data['googleMapsLink'],
        data['googleMapsUrl'],
        data['mapsUrl'],
        posts['mapLink'],
        posts['googleMapLink'],
        posts['googleMapsLink'],
        posts['googleMapsUrl'],
        posts['mapsUrl'],
        events['mapLink'],
        events['googleMapLink'],
        events['googleMapsLink'],
        events['googleMapsUrl'],
        events['mapsUrl'],
        directMap,
      ]),
      ticket: _firstText([
        ticketFromLinks,
        data['ticketLink'],
        data['ticketUrl'],
        data['bookingLink'],
        data['bookingUrl'],
        posts['ticketLink'],
        posts['ticketUrl'],
        posts['bookingLink'],
        posts['bookingUrl'],
        events['ticketLink'],
        events['ticketUrl'],
        events['bookingLink'],
        events['bookingUrl'],
        directTicket,
      ]),
    );
  }

  static String _linkByKind(List<Map<String, dynamic>> links, _LinkKind kind) {
    for (final link in links) {
      final label = _firstText([
        link['name'],
        link['label'],
        link['title'],
        link['type'],
      ]);
      final url = _firstText([
        link['url'],
        link['href'],
        link['link'],
        link['value'],
      ]);
      if (url.isNotEmpty && _matchesLinkKind(label, url, kind)) {
        return url;
      }
    }
    return '';
  }

  static String _firstDirectLinkByKind(List<String> urls, _LinkKind kind) {
    for (final url in urls) {
      if (url.isNotEmpty && _matchesLinkKind('', url, kind)) {
        return url;
      }
    }
    return '';
  }

  static bool _matchesLinkKind(String label, String url, _LinkKind kind) {
    final value = '$label $url'.toLowerCase();
    switch (kind) {
      case _LinkKind.website:
        return !_looksLikeMapLink(value) && !_looksLikeTicketLink(value);
      case _LinkKind.map:
        return _looksLikeMapLink(value);
      case _LinkKind.ticket:
        return _looksLikeTicketLink(value);
    }
  }

  static bool _looksLikeMapLink(String value) {
    return value.contains('map') ||
        value.contains('maps.google') ||
        value.contains('google.com/maps') ||
        value.contains('place_id:') ||
        value.startsWith('geo:');
  }

  static bool _looksLikeTicketLink(String value) {
    return value.contains('ticket') ||
        value.contains('booking') ||
        value.contains('book now') ||
        value.contains('reservation') ||
        value.contains('reserve');
  }

  static String _firstFromIterable(Object? value) {
    if (value is! Iterable) {
      return '';
    }

    for (final item in value) {
      final text = _text(item);
      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  static List<String> _tagLabels(Object? value) {
    final labels = <String>[];

    void addLabel(Object? rawValue) {
      if (rawValue == null) {
        return;
      }

      if (rawValue is Iterable) {
        for (final item in rawValue) {
          addLabel(item);
        }
        return;
      }

      if (rawValue is Map) {
        final map = _map(rawValue);
        addLabel([
          map['tagName'],
          map['tag_name'],
          map['name'],
          map['title'],
          map['label'],
          map['value'],
          map['id'],
          map['tagId'],
          map['tag_id'],
        ]);
        return;
      }

      final label = _labelFrom([rawValue]);
      if (label.isNotEmpty) {
        labels.add(label);
      }
    }

    addLabel(value);
    return labels.toSet().toList();
  }

  static String _featureLabel(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
    Map<String, dynamic> events = const {},
  ]) {
    return _labelFrom([
      data['feature'],
      data['featureName'],
      data['filter'],
      data['filterName'],
      posts['feature'],
      posts['featureName'],
      posts['filter'],
      posts['filterName'],
      events['feature'],
      events['featureName'],
      events['filter'],
      events['filterName'],
    ]).ifEmpty(AppStrings.featured);
  }

  static List<SocialPostItem> _socialPostsFrom(
    Map<String, dynamic> data, {
    required String fallbackImage,
  }) {
    final socialPosts = [
      ..._maps(data['socialPosts']),
      ..._maps(data['social_posts']),
      ..._maps(data['socialPost']),
      ..._maps(data['social_post']),
      ..._maps(data['postItems']),
      ..._maps(data['post_items']),
    ];
    final posts = socialPosts.isNotEmpty ? socialPosts : _maps(data['posts']);
    if (posts.isEmpty) {
      return const [];
    }

    return posts.where(_looksLikeSocialPost).indexed.map((entry) {
      final index = entry.$1;
      final post = entry.$2;
      final platform = _text(post['platform']).ifEmpty(AppStrings.instagram);
      final normalizedPlatform = platform.toLowerCase();
      final image = _firstText([
        post['thumbnailUrl'],
        post['thumbnail_url'],
        post['thumbUrl'],
        post['thumb_url'],
        post['imageUrl'],
        post['image_url'],
        post['imageURL'],
        post['mediaUrl'],
        post['media_url'],
        post['postImageUrl'],
        post['post_image_url'],
        post['thumbnail'],
        post['image'],
        fallbackImage,
      ]);

      return SocialPostItem(
        id: _text(
          post['id'],
        ).ifEmpty('${_text(data['slug']).ifEmpty('post')}-$index'),
        username: _userName(post),
        platform: _humanizedLabel(platform),
        platformIconPath: normalizedPlatform.contains('tiktok')
            ? AppImages.tiktokIcon
            : AppImages.instagramIcon,
        avatarImagePath: _firstText([
          post['avatarUrl'],
          post['avatar_url'],
          post['userAvatar'],
          post['user_avatar'],
          post['userAvatarUrl'],
          post['user_avatar_url'],
          post['avatarImageUrl'],
          post['avatar_image_url'],
        ]),
        imagePath: image,
        caption: _firstText([
          post['description'],
          post['caption'],
          data['description'],
          data['title'],
        ]),
        tags: _tagsLabel(post['tags']),
        showPlayIcon: normalizedPlatform.contains('tiktok'),
      );
    }).toList();
  }

  static bool _looksLikeSocialPost(Map<String, dynamic> post) {
    return _firstText([
      post['platform'],
      post['userName'],
      post['username'],
      post['avatarUrl'],
      post['userAvatar'],
      post['thumbnailUrl'],
      post['thumbnail_url'],
      post['thumbnail'],
      post['imageUrl'],
      post['image_url'],
      post['caption'],
      post['description'],
    ]).isNotEmpty;
  }

  static String _userName(Map<String, dynamic> post) {
    final value = _firstText([
      post['userName'],
      post['username'],
      post['name'],
    ]);
    if (value.isEmpty) {
      return '@chillingz';
    }
    return value.startsWith('@') ? value : '@$value';
  }

  static String _tagsLabel(Object? value) {
    if (value is Iterable) {
      final tags = value
          .map((item) => _text(item))
          .where((item) => item.isNotEmpty)
          .map((item) => item.startsWith('#') ? item : '#$item')
          .join('   ');
      return tags;
    }

    final text = _text(value);
    if (text.isEmpty) {
      return '';
    }

    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map((item) => item.startsWith('#') ? item : '#$item')
        .join('   ');
  }

  static List<String> _sortedFilters(Set<String> filters) {
    final byNormalizedValue = <String, String>{};
    for (final filter in filters) {
      final trimmed = filter.trim();
      final key = trimmed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
      if (trimmed.isEmpty ||
          key.isEmpty ||
          key == 'cuisines' ||
          _isInvalidSubcategoryLabel(trimmed)) {
        continue;
      }
      byNormalizedValue.putIfAbsent(key, () => trimmed);
    }

    final sortedFilters = byNormalizedValue.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sortedFilters;
  }

  static List<String> _mergeFilters(Iterable<String> filters) {
    return _sortedFilters(filters.toSet());
  }

  static List<String> _filtersFromMusicEvents(Iterable<MusicEventItem> items) {
    return items
        .expand((item) => [item.feature?.trim() ?? '', item.subcategory.trim()])
        .where((filter) => filter.isNotEmpty)
        .toList();
  }

  static List<String> _filtersFromDetails(Iterable<SavedDetailItem> items) {
    return items
        .expand(
          (item) => [
            item.feature?.trim() ?? '',
            item.subcategory.trim(),
            item.activityType.trim(),
          ],
        )
        .where((filter) => filter.isNotEmpty)
        .toList();
  }

  static bool _isNatureDiscovery(String title, String tag) {
    final value = '$title $tag'.toLowerCase();
    return value.contains('nature') ||
        value.contains('outdoor') ||
        value.contains('waterfall');
  }

  static List<MusicGenreItem> _uniqueMusicGenres(List<MusicGenreItem> items) {
    final seen = <String>{};
    final uniqueItems = <MusicGenreItem>[];

    for (final item in items) {
      final key = item.title.toLowerCase();
      if (seen.add(key)) {
        uniqueItems.add(item);
      }
    }

    return uniqueItems;
  }

  static List<FoodCuisineItem> _uniqueFoodCuisineItems(
    List<FoodCuisineItem> items,
  ) {
    final seen = <String>{};
    final uniqueItems = <FoodCuisineItem>[];

    for (final item in items) {
      final key = item.title.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]+'),
        '',
      );
      if (key.isNotEmpty && seen.add(key)) {
        uniqueItems.add(item);
      }
    }

    return uniqueItems;
  }

  /// Currency codes mapped to the symbol/prefix shown to the user. Falls
  /// back to the code itself (e.g. "AED 10") when there is no common symbol.
  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'POUND': '£',
    'INR': '₹',
    'JPY': '¥',
    'CAD': 'CA\$',
    'AUD': 'AU\$',
  };

  /// Resolves the symbol/prefix to show for a currency value fetched from
  /// Firebase (e.g. "GBP", "USD", or an already-formatted symbol like "£").
  /// Only falls back to £ when Firebase has no currency data at all.
  static String _currencySymbol(String currency) {
    final trimmed = currency.trim();
    if (trimmed.isEmpty) {
      return '£';
    }
    // Already a symbol rather than a currency code — use it as-is.
    if (!RegExp(r'^[A-Za-z]+$').hasMatch(trimmed)) {
      return trimmed;
    }
    final code = trimmed.toUpperCase();
    return _currencySymbols[code] ?? '$code ';
  }

  static String _priceLabel(Object? value, [Object? currency]) {
    var text = _text(value);
    if (text.isEmpty) {
      return '';
    }
    final normalized = text.toLowerCase();
    if (normalized.startsWith('price')) {
      text = text.replaceFirst(
        RegExp(r'^price\s*:\s*', caseSensitive: false),
        '',
      );
    }
    if (text.toLowerCase() == 'free') {
      return 'Free';
    }
    // Strip any currency symbol/code already embedded in the price text so
    // it isn't duplicated once the real currency (from Firebase) is applied.
    text = text.replaceFirst(RegExp(r'^[\$€£¥₹]\s*'), '');
    text = text.replaceFirst(
      RegExp(r'^(USD|EUR|EURO|GBP|POUND|PKR|AED|INR)\s*', caseSensitive: false),
      '',
    );
    return '${_currencySymbol(_text(currency))}$text';
  }

  static Object? _priceValue(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
    Map<String, dynamic> events = const {},
  ]) {
    return events['price'] ??
        events['price_from'] ??
        events['priceFrom'] ??
        events['price_range'] ??
        events['priceRange'] ??
        posts['price'] ??
        posts['price_from'] ??
        posts['priceFrom'] ??
        posts['price_range'] ??
        posts['priceRange'] ??
        data['price'] ??
        data['price_from'] ??
        data['priceFrom'] ??
        data['price_range'] ??
        data['priceRange'];
  }

  static String _currency(
    Map<String, dynamic> data, [
    Map<String, dynamic> posts = const {},
    Map<String, dynamic> events = const {},
  ]) {
    return _firstText([
      events['priceCurrency'],
      events['price_currency'],
      events['currency'],
      events['currencyCode'],
      data['priceCurrency'],
      data['price_currency'],
      data['currency'],
      data['currencyCode'],
      posts['priceCurrency'],
      posts['price_currency'],
      posts['currency'],
      posts['currencyCode'],
    ]);
  }

  static String _rating(Object? value) {
    final text = _text(value);
    if (text.isEmpty || text == '0') {
      return '';
    }
    return text;
  }

  static String _dateBadge(Object? value) {
    final date = _asDate(value);
    if (date == null) {
      return '';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]}\n${date.day}';
  }

  static DateTime? _asDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(_text(value));
  }

  static IconData _categoryIcon(String slug, String iconName) {
    final value = '$slug $iconName'.toLowerCase();
    if (value.contains('music')) {
      return Icons.music_note_outlined;
    }
    if (value.contains('calendar') || value.contains('event')) {
      return Icons.event_outlined;
    }
    if (value.contains('food') || value.contains('drink')) {
      return Icons.restaurant_outlined;
    }
    if (value.contains('health') || value.contains('well')) {
      return Icons.spa_outlined;
    }
    if (value.contains('network')) {
      return Icons.groups_outlined;
    }
    return Icons.explore_outlined;
  }

  static String? _categoryRoute(String slug, String title) {
    final value = '$slug $title'.toLowerCase();
    if (value.contains('music')) {
      return AppRoutes.music;
    }
    if (value.contains('event')) {
      return AppRoutes.events;
    }
    if (value.contains('food') || value.contains('drink')) {
      return AppRoutes.foodDrink;
    }
    if (value.contains('health') || value.contains('well')) {
      return AppRoutes.healthWellbeing;
    }
    if (value.contains('network')) {
      return AppRoutes.networking;
    }
    if (value.contains('activit') || value.contains('adventure')) {
      return AppRoutes.activities;
    }
    return null;
  }

  static Color _backgroundColor(_ContentBucket bucket) {
    switch (bucket) {
      case _ContentBucket.activities:
        return AppColors.activitiesCardBackground;
      case _ContentBucket.food:
        return AppColors.foodCardBackground;
      case _ContentBucket.health:
        return AppColors.healthCardBackground;
      case _ContentBucket.networking:
        return AppColors.networkingCardBackground;
      case _ContentBucket.events:
      case _ContentBucket.music:
        return AppColors.activitiesCardBackground;
    }
  }
}

class _GenreBundle {
  const _GenreBundle({
    required this.genres,
    required this.musicEvents,
    required this.eventItems,
  });

  final List<MusicGenreItem> genres;
  final List<MusicEventItem> musicEvents;
  final List<MusicEventItem> eventItems;
}

class _SubcategoryBundle {
  const _SubcategoryBundle({
    required this.foodCuisines,
    required this.activitySubcategories,
    required this.healthSubcategories,
    required this.networkingSubcategories,
    required this.musicGenres,
    required this.activityFilters,
    required this.foodFilters,
    required this.eventFilters,
    required this.musicFilters,
    required this.healthFilters,
    required this.networkingFilters,
  });

  final List<FoodCuisineItem> foodCuisines;
  final List<FoodCuisineItem> activitySubcategories;
  final List<FoodCuisineItem> healthSubcategories;
  final List<FoodCuisineItem> networkingSubcategories;
  final List<MusicGenreItem> musicGenres;
  final List<String> activityFilters;
  final List<String> foodFilters;
  final List<String> eventFilters;
  final List<String> musicFilters;
  final List<String> healthFilters;
  final List<String> networkingFilters;
}

class _ContentBundle {
  const _ContentBundle({
    required this.activityItems,
    required this.foodPlaces,
    required this.healthItems,
    required this.networkingItems,
    required this.eventItems,
    required this.musicEvents,
  });

  final List<SavedDetailItem> activityItems;
  final List<SavedDetailItem> foodPlaces;
  final List<SavedDetailItem> healthItems;
  final List<SavedDetailItem> networkingItems;
  final List<MusicEventItem> eventItems;
  final List<MusicEventItem> musicEvents;
}

class _LinkBundle {
  const _LinkBundle({
    required this.website,
    required this.map,
    required this.ticket,
  });

  final String website;
  final String map;
  final String ticket;
}

enum _ContentBucket { activities, food, health, networking, events, music }

enum _LinkKind { website, map, ticket }

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
