// map_dialog_widget.dart
import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/screen/caretaker/controllers/location_controller.dart';
import 'package:autism_care_management_application/utils/validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapDialogWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final LocationService locationService;

  MapDialogWidget({
    super.key,
    this.initialLocation,
    required this.locationService,
  });

  @override
  State<MapDialogWidget> createState() => _MapDialogWidgetState();
}

class _MapDialogWidgetState extends State<MapDialogWidget> {
  final TextEditingController _searchController = TextEditingController();
  late MapController _mapController;
  late Map<String, dynamic> _currentLocation;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _currentLocation = {
      'placeName': 'Select a location',
      'placeAddress': 'Tap on the map or search',
      'latitude': widget.initialLocation?.latitude ?? 37.7749,
      'longitude': widget.initialLocation?.longitude ?? -122.4194,
    };
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await widget.locationService.searchLocation(query);

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching location: $e')));
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _selectLocation(LatLng location) async {
    final locationDetails = await widget.locationService.getLocationDetails(
      location,
    );

    setState(() {
      _currentLocation = locationDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Select Location',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search location...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _searchLocation,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () => _searchLocation(_searchController.text),
                    child: const Text('Search'),
                  ),
                ),
              ],
            ),

            // Search results
            if (_isSearching)
              const Padding(padding: EdgeInsets.all(8.0), child: CustomLoader())
            else if (_searchResults.isNotEmpty)
              Container(
                height: 100,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      title: Text(result['placeName']),
                      subtitle: Text(
                        '${result['latitude'].toStringAsFixed(6)}, ${result['longitude'].toStringAsFixed(6)}',
                      ),
                      onTap: () {
                        _mapController.move(
                          LatLng(result['latitude'], result['longitude']),
                          15.0,
                        );
                        setState(() {
                          _currentLocation = result;
                          _searchResults = [];
                          _searchController.clear();
                        });
                      },
                    );
                  },
                ),
              ),

            // Map
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      _currentLocation['latitude'],
                      _currentLocation['longitude'],
                    ),
                    initialZoom: 13.0,
                    onTap: (_, point) => _selectLocation(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: LatLng(
                            _currentLocation['latitude'],
                            _currentLocation['longitude'],
                          ),
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Selected location info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Place: ${_currentLocation['placeName']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Address: ${_currentLocation['placeAddress']}'),
                  const SizedBox(height: 4),
                  Text(
                    'Coordinates: ${_currentLocation['latitude'].toStringAsFixed(6)}, ${_currentLocation['longitude'].toStringAsFixed(6)}',
                  ),
                ],
              ),
            ),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 160,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        LatLng(
                          _currentLocation['latitude'],
                          _currentLocation['longitude'],
                        ),
                      );
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
