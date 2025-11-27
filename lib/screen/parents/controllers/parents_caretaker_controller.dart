// caretaker_controller.dart
import 'package:autism_care_management_application/screen/parents/model/caretaker_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapsController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Caretaker> caretakers = [];
  final ValueNotifier<List<Caretaker>> caretakersNotifier =
      ValueNotifier<List<Caretaker>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String> errorMessage = ValueNotifier<String>('');
  final ValueNotifier<LatLng> currentLocation = ValueNotifier<LatLng>(
    LatLng(3.1390, 101.6869),
  );

  // Track if controller is disposed
  bool _isDisposed = false;

  /////////////////////////////// AUTISM MAP /////////////////////////////////////////////////

  // Add radius filter
  double _radiusFilterMeters = 0; // 0 means no filter
  String _searchQuery = '';

  Future<void> getCurrentLocation() async {
    if (_isDisposed) return;

    isLoading.value = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!_isDisposed)
          errorMessage.value =
              'Location services are disabled, \nplease enable location in your settings.';
        if (!_isDisposed) isLoading.value = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!_isDisposed)
            errorMessage.value =
                'Location permissions are denied, \nplease enable location in your settings.';
          if (!_isDisposed) isLoading.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!_isDisposed)
          errorMessage.value =
              'Location permissions are permanently denied, \nplease enable location in your settings.';
        if (!_isDisposed) isLoading.value = false;
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (!_isDisposed) {
        currentLocation.value = LatLng(position.latitude, position.longitude);
        fetchCaretakers(); // Refresh caretakers based on new location
      }
    } catch (e) {
      if (!_isDisposed) errorMessage.value = 'Error getting location: $e';
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  Future<void> fetchCaretakers() async {
    if (_isDisposed) return;

    isLoading.value = true;
    caretakers.clear();

    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('caretaker').get();

      for (var doc in snapshot.docs) {
        try {
          Caretaker caretaker = Caretaker.fromFirestore(doc);
          caretakers.add(caretaker);
        } catch (e) {
          print('Error parsing caretaker document: $e');
        }
      }

      // Apply filters and sorting
      if (!_isDisposed) _applyFiltersAndSort();
    } catch (e) {
      if (!_isDisposed) errorMessage.value = 'Error fetching caretakers: $e';
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  void searchCaretakers(String query) {
    if (_isDisposed) return;
    _searchQuery = query;
    _applyFiltersAndSort();
  }

  void setRadiusFilter(double radiusMeters) {
    if (_isDisposed) return;
    _radiusFilterMeters = radiusMeters;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    if (_isDisposed) return;

    List<Caretaker> filteredCaretakers = List.from(caretakers);

    // Apply search filter first
    if (_searchQuery.isNotEmpty) {
      filteredCaretakers = filteredCaretakers.where((caretaker) {
        return caretaker.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
            caretaker.specialization.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
            caretaker.address.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
      }).toList();
    }

    // Sort by distance (nearest first)
    filteredCaretakers.sort((a, b) {
      double distA = calculateDistance(currentLocation.value, a.location);
      double distB = calculateDistance(currentLocation.value, b.location);
      return distA.compareTo(distB);
    });

    // Apply radius filter after sorting
    if (_radiusFilterMeters > 0) {
      filteredCaretakers = filteredCaretakers.where((caretaker) {
        double distance = calculateDistance(
          currentLocation.value,
          caretaker.location,
        );
        return distance * 1000 <= _radiusFilterMeters;
      }).toList();
    }

    caretakersNotifier.value = filteredCaretakers;
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
          point1.latitude,
          point1.longitude,
          point2.latitude,
          point2.longitude,
        ) /
        1000;
  }

  Future<void> sortCaretakersByDistance() async {
    if (_isDisposed) return;
    _applyFiltersAndSort();
  }

  void dispose() {
    _isDisposed = true;
    isLoading.dispose();
    errorMessage.dispose();
    caretakersNotifier.dispose();
    currentLocation.dispose();
  }

  /////////////////////////////////////// AUTISM ATTENDANCE //////////////////////////////////////////

  Future<Position?> getCurrentLocationForAttendance() async {
    if (_isDisposed) return null;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  double calculateDistanceForAttendance(
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
    );
  }

  bool isWithinRadius(
    double currentLat,
    double currentLng,
    double targetLat,
    double targetLng,
    double radiusInMeters,
  ) {
    double distance = calculateDistanceForAttendance(
        currentLat, currentLng, targetLat, targetLng);
    return distance <= radiusInMeters;
  }
}
