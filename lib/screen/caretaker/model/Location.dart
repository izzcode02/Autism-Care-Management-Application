class LocationData {
  final String placeName;
  final String placeAddress;
  final double latitude;
  final double longitude;

  LocationData({
    required this.placeName,
    required this.placeAddress,
    required this.latitude,
    required this.longitude,
  });

  // Convert to and from JSON
  Map<String, dynamic> toJson() => {
        'placeName': placeName,
        'placeAddress': placeAddress,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      placeName: json['placeName'],
      placeAddress: json['placeAddress'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  // Default location data when none exists
  factory LocationData.defaultData() {
    return LocationData(
      placeName: 'Not set',
      placeAddress: 'Not set',
      latitude: 0.0,
      longitude: 0.0,
    );
  }

  // Create a copy with some parameters changed
  LocationData copyWith({
    String? placeName,
    String? placeAddress,
    double? latitude,
    double? longitude,
  }) {
    return LocationData(
      placeName: placeName ?? this.placeName,
      placeAddress: placeAddress ?? this.placeAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}