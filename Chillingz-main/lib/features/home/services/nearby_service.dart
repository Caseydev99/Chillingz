import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

class NearbyVenue {
  const NearbyVenue({
    required this.id,
    required this.collection,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  final String id;
  final String collection;
  final String city;
  final double latitude;
  final double longitude;
  final double distanceKm;
}

class NearbyService {
  NearbyService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const double nearbyRadiusKm = 30;

  final FirebaseFirestore _firestore;

  Future<List<NearbyVenue>> fetchNearbyVenues({
    required UserLocation userLocation,
  }) async {
    final snapshots = await Future.wait([
      _firestore.collection('venues').get(),
      _firestore.collection('subcategoriesContent').get(),
      _firestore.collection('listingCategories').get(),
      _firestore.collection('chillingz').get(),
      _firestore.collection('genres').get(),
    ]);

    final nearbyVenues = <NearbyVenue>[];
    for (var index = 0; index < snapshots.length; index++) {
      final collection = _collections[index];
      for (final doc in snapshots[index].docs) {
        final data = doc.data();
        if (!_isActive(data)) {
          continue;
        }

        final city = _venueCity(data);
        final latitude = _venueLatitude(data);
        final longitude = _venueLongitude(data);
        if (city.isEmpty || latitude == null || longitude == null) {
          continue;
        }

        final distanceKm = distanceBetweenKm(
          userLocation.latitude,
          userLocation.longitude,
          latitude,
          longitude,
        );
        if (isNearbyVenue(
          userLocation: userLocation,
          venueCity: city,
          venueLatitude: latitude,
          venueLongitude: longitude,
        )) {
          nearbyVenues.add(
            NearbyVenue(
              id: doc.id,
              collection: collection,
              city: city,
              latitude: latitude,
              longitude: longitude,
              distanceKm: distanceKm,
            ),
          );
        }
      }
    }

    return nearbyVenues;
  }

  bool isNearbyVenue({
    required UserLocation? userLocation,
    required String? venueCity,
    required double? venueLatitude,
    required double? venueLongitude,
  }) {
    if (userLocation == null ||
        venueCity == null ||
        venueCity.trim().isEmpty ||
        venueLatitude == null ||
        venueLongitude == null) {
      return false;
    }

    if (_sameMetroRegion(userLocation.city, venueCity)) {
      return true;
    }

    return distanceBetweenKm(
          userLocation.latitude,
          userLocation.longitude,
          venueLatitude,
          venueLongitude,
        ) <=
        nearbyRadiusKm;
  }

  static double distanceBetweenKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000;
  }

  static bool _sameMetroRegion(String userCity, String venueCity) {
    final userRegion = _normalizedRegion(userCity);
    final venueRegion = _normalizedRegion(venueCity);
    return userRegion.isNotEmpty && userRegion == venueRegion;
  }

  static String _normalizedRegion(String city) {
    final normalized = city.trim().toLowerCase();
    if (normalized == 'islamabad' || normalized == 'rawalpindi') {
      return 'islamabad-rawalpindi';
    }
    return normalized;
  }

  static bool _isActive(Map<String, dynamic> data) {
    final status = data['status']?.toString().trim().toLowerCase() ?? '';
    if (status.isNotEmpty) {
      return status == 'active';
    }

    final isActive = data['is_active'];
    return isActive is bool ? isActive : true;
  }

  static String _venueCity(Map<String, dynamic> data) {
    return _firstText([
      data['city'],
      _map(data['venue'])['city'],
      _map(data['location'])['city'],
      _map(data['posts'])['city'],
      _map(data['events'])['city'],
    ]);
  }

  static double? _venueLatitude(Map<String, dynamic> data) {
    return _firstNumber([
      data['latitude'],
      data['lat'],
      _map(data['venue'])['latitude'],
      _map(data['venue'])['lat'],
      _map(data['location'])['latitude'],
      _map(data['location'])['lat'],
      _map(data['posts'])['latitude'],
      _map(data['posts'])['lat'],
      _map(data['events'])['latitude'],
      _map(data['events'])['lat'],
    ]);
  }

  static double? _venueLongitude(Map<String, dynamic> data) {
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
      _map(data['posts'])['longitude'],
      _map(data['posts'])['lng'],
      _map(data['posts'])['lon'],
      _map(data['events'])['longitude'],
      _map(data['events'])['lng'],
      _map(data['events'])['lon'],
    ]);
  }

  static String _firstText(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
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

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static const List<String> _collections = [
    'venues',
    'subcategoriesContent',
    'listingCategories',
    'chillingz',
    'genres',
  ];
}
