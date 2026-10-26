import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class UserLocation {
  const UserLocation({
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final double latitude;
  final double longitude;
}

class LocationService {
  LocationService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<LocationPermission> checkPermissionStatus() {
    return Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermissionStatus() {
    return Geolocator.requestPermission();
  }

  Future<bool> requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<UserLocation?> getCurrentUserLocation() async {
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      return null;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    final city = await reverseGeocodeCity(
      position.latitude,
      position.longitude,
    );

    return UserLocation(
      city: city,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<String> reverseGeocodeCity(
    double latitude,
    double longitude,
  ) async {
    // The geocoding plugin has no web implementation, so browsers use
    // BigDataCloud's key-free client-side reverse geocoder instead.
    if (kIsWeb) {
      return _reverseGeocodeCityOnWeb(latitude, longitude);
    }

    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) {
      return '';
    }

    final placemark = placemarks.first;
    return [
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ].whereType<String>().map((value) => value.trim()).firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => '',
        );
  }

  Future<String> _reverseGeocodeCityOnWeb(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.https(
        'api.bigdatacloud.net',
        '/data/reverse-geocode-client',
        {
          'latitude': '$latitude',
          'longitude': '$longitude',
          'localityLanguage': 'en',
        },
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return '';
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return [
        data['city'],
        data['locality'],
        data['principalSubdivision'],
      ].whereType<String>().map((value) => value.trim()).firstWhere(
            (value) => value.isNotEmpty,
            orElse: () => '',
          );
    } catch (_) {
      return '';
    }
  }

  Future<UserLocation?> updateCurrentUserLocation() async {
    final userLocation = await getCurrentUserLocation();
    final user = _firebaseAuth.currentUser;
    if (userLocation == null || user == null) {
      return userLocation;
    }

    await saveUserLocation(user.uid, userLocation);
    return userLocation;
  }

  Future<void> saveUserLocation(
    String userId,
    UserLocation userLocation,
  ) async {
    await _firestore.collection('users').doc(userId).set({
      'city': userLocation.city,
      'latitude': userLocation.latitude,
      'longitude': userLocation.longitude,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserLocation?> fetchSavedUserLocation(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    final latitude = _number(data['latitude']);
    final longitude = _number(data['longitude']);
    final city = data['city']?.toString().trim() ?? '';
    if (city.isEmpty || latitude == null || longitude == null) {
      return null;
    }

    return UserLocation(
      city: city,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static double? _number(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }
}
