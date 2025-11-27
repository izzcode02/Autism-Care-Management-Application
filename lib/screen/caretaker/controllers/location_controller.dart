// location_service.dart
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  // Get location details from coordinates
  Future<Map<String, dynamic>> getLocationDetails(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final placeName = place.name ?? place.locality ?? 'Unknown Place';
        final placeAddress = [
          place.street,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
        
        return {
          'placeName': placeName,
          'placeAddress': placeAddress,
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      }
    } catch (e) {
      print('Error getting location details: $e');
    }
    
    return {
      'placeName': 'Unknown Location',
      'placeAddress': 'Address not available',
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }

  // Search for location by query
  Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    if (query.isEmpty) return [];

    try {
      List<Location> locations = await locationFromAddress(query);
      
      return locations.map((location) => {
        'placeName': query,
        'placeAddress': query,
        'latitude': location.latitude,
        'longitude': location.longitude,
      }).toList();
    } catch (e) {
      print('Error searching location: $e');
      return [];
    }
  }
}