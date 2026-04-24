import 'dart:math';
import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/common/widgets/video_player_widget.dart';
import 'package:autism_care_management_application/data/services/permission_handler.dart';
import 'package:autism_care_management_application/screen/caretaker/controllers/caretaker_controller.dart';
import 'package:autism_care_management_application/screen/caretaker/model/media_model.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_caretaker_controller.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:autism_care_management_application/screen/parents/model/caretaker_model.dart';
import 'package:autism_care_management_application/screen/parents/model/parents_model.dart';
import 'package:autism_care_management_application/screen/parents/views/p_maps_review.dart';
import 'package:autism_care_management_application/screen/parents/views/p_maps_web_view.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:autism_care_management_application/screen/parents/model/children_model.dart';

class CaretakerMapView extends StatefulWidget {
  const CaretakerMapView({Key? key}) : super(key: key);

  @override
  State<CaretakerMapView> createState() => _CaretakerMapViewState();
}

enum Days { Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday }

class _CaretakerMapViewState extends State<CaretakerMapView> {
  final _key = GlobalKey<ExpandableFabState>();
  final _controller = MapsController();
  final parentController = FirestoreService();
  final permission = PermissionHandler();
  final _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<Marker> _markers = [];

  // Circle radius in meters (1km = 1000m), by default it will be zero
  double circleRadiusMeters = 0;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _controller.getCurrentLocation();
  }

  void _setupListeners() {
    _controller.currentLocation.addListener(_updateMapCenter);
    _controller.caretakersNotifier.addListener(_updateMarkers);
    _controller.errorMessage.addListener(_showErrorSnackBar);
  }

  void _updateMapCenter() {
    _mapController.move(_controller.currentLocation.value, 13.0);
    _updateMarkers();
  }

  void _showErrorSnackBar() {
    if (_controller.errorMessage.value.isNotEmpty) {
      AwesomeDialog(
        context: context,
        dialogType:
            DialogType.error, // or other type like DialogType.warning, etc.
        animType: AnimType.bottomSlide,
        title: 'Error',
        desc: _controller.errorMessage.value,
        btnOkOnPress: () {},
        btnOkColor: Colors.red, // optional color customization
      ).show();
    }
  }

  // Helper method to generate circle boundary points for more precise visualization
  List<LatLng> _generateCirclePoints(LatLng center, double radiusInMeters) {
    List<LatLng> points = [];
    const int numPoints = 64; // Number of points to create smooth circle
    const double earthRadius = 6371000; // Earth's radius in meters

    for (int i = 0; i < numPoints; i++) {
      double angle = (i * 2 * pi) / numPoints;

      // Calculate new point using haversine formula
      double lat1Rad = center.latitude * (pi / 180);
      double lng1Rad = center.longitude * (pi / 180);

      double angularDistance = radiusInMeters / earthRadius;

      double lat2Rad = asin(
        sin(lat1Rad) * cos(angularDistance) +
            cos(lat1Rad) * sin(angularDistance) * cos(angle),
      );

      double lng2Rad = lng1Rad +
          atan2(
            sin(angle) * sin(angularDistance) * cos(lat1Rad),
            cos(angularDistance) - sin(lat1Rad) * sin(lat2Rad),
          );

      double lat2 = lat2Rad * (180 / pi);
      double lng2 = lng2Rad * (180 / pi);

      points.add(LatLng(lat2, lng2));
    }

    return points;
  }

  void _updateMarkers() {
    setState(() {
      // Start with current location marker
      _markers = [
        Marker(
          point: _controller.currentLocation.value,
          child: const Icon(Icons.location_on, color: Colors.blue, size: 30.0),
        ),
      ];

      // Add markers for caretakers (these are already filtered and sorted by the controller)
      for (var caretaker in _controller.caretakersNotifier.value) {
        _markers.add(
          Marker(
            point: caretaker.location,
            child: GestureDetector(
              onTap: () => _showCaretakerDetails(caretaker),
              child: Transform.scale(
                scale: 2,
                child: Column(
                  children: [
                    Icon(Icons.location_pin, color: Colors.red, size: 15.0),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        caretaker.name,
                        style: const TextStyle(fontSize: 8),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    });
  }

  Future<Parent?> _getParentInfo() async {
    try {
      return await parentController.getParent();
    } catch (e) {
      print('Error getting parent info: $e');
      return null;
    }
  }

  Future<void> _showCaretakerDetails(Caretaker caretaker) async {
    final parent = await _getParentInfo();

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CaretakerDetailView(
          caretaker: caretaker,
          currentLocation: _controller.currentLocation.value,
          parent: parent,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // Method to handle radius filter changes
  void _updateRadiusFilter(double radiusMeters) {
    setState(() {
      circleRadiusMeters = radiusMeters;
    });
    // Update the controller's radius filter
    _controller.setRadiusFilter(radiusMeters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Caretakers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              await permission
                  .requestLocationPermission(context)
                  .then((_) => _controller.getCurrentLocation());
            },
          ),
          IconButton(
              icon: const Icon(Icons.inbox),
              onPressed: () {
                Navigator.pushNamed(context, '/parents/findcenter/inbox');
              }),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for caretakers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _controller.searchCaretakers('');
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onChanged: (value) => _controller.searchCaretakers(value),
            ),
          ),

          // Map and loading indicator
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _controller.currentLocation.value,
                    initialZoom: 13.0,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onTap: (_, point) {
                      // Dismiss keyboard when map is tapped
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.autism.care.app',
                    ),

                    // Using PolygonLayer for more precise circle
                    // Only show circle if radius > 0
                    if (circleRadiusMeters > 0)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: _generateCirclePoints(
                              _controller.currentLocation.value,
                              circleRadiusMeters,
                            ),
                            color: Colors.blue.withOpacity(0.2),
                            borderColor: Colors.blue,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    MarkerLayer(markers: _markers),
                  ],
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _controller.isLoading,
                  builder: (context, isLoading, _) {
                    return isLoading
                        ? const Center(child: CustomLoader())
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // List of nearby caretakers
          ValueListenableBuilder<List<Caretaker>>(
            valueListenable: _controller.caretakersNotifier,
            builder: (context, caretakers, _) {
              return Container(
                height: 120,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: caretakers.isEmpty
                    ? Center(
                        child: Text(
                          circleRadiusMeters > 0
                              ? 'No caretakers found within ${(circleRadiusMeters / 1000).toStringAsFixed(0)}km radius'
                              : 'No caretakers found',
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: caretakers.length,
                        itemBuilder: (context, index) {
                          final caretaker = caretakers[index];
                          final distance = _controller.calculateDistance(
                            _controller.currentLocation.value,
                            caretaker.location,
                          );

                          return Container(
                            width: 150,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Card(
                              elevation: 2,
                              child: InkWell(
                                onTap: () => _showCaretakerDetails(caretaker),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        caretaker.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        caretaker.specialization,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 14,
                                          ),
                                          Text(
                                            '${distance.toStringAsFixed(1)} km',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        ],
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: _key,
        overlayStyle: ExpandableFabOverlayStyle(
          color: Colors.black.withValues(alpha: 0.5),
          blur: 5,
        ),
        onOpen: () {
          debugPrint('onOpen');
        },
        afterOpen: () {
          debugPrint('afterOpen');
        },
        onClose: () {
          debugPrint('onClose');
        },
        afterClose: () {
          debugPrint('afterClose');
        },
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          fabSize: ExpandableFabSize.small,
          child: const Icon(Icons.filter_alt),
          foregroundColor: Colors.yellow,
          shape: const CircleBorder(),
          angle: 3.14 * 2,
          elevation: 5,
        ),
        children: [
          FloatingActionButton(
            mini: true,
            shape: const CircleBorder(),
            heroTag: 'off_filter',
            backgroundColor: circleRadiusMeters == 0 ? Colors.blue : null,
            child: Text('OFF'.toUpperCase(), style: TextStyle(fontSize: 10)),
            onPressed: () {
              _updateRadiusFilter(0);
              _key.currentState?.toggle();
            },
          ),
          FloatingActionButton(
            mini: true,
            shape: const CircleBorder(),
            heroTag: '1km_filter',
            backgroundColor: circleRadiusMeters == 1000 ? Colors.blue : null,
            child: Text('1km', style: TextStyle(fontSize: 10)),
            onPressed: () {
              _updateRadiusFilter(1000);
              _key.currentState?.toggle();
            },
          ),
          FloatingActionButton(
            mini: true,
            shape: const CircleBorder(),
            heroTag: '10km_filter',
            backgroundColor: circleRadiusMeters == 10000 ? Colors.blue : null,
            child: Text('10km', style: TextStyle(fontSize: 10)),
            onPressed: () {
              _updateRadiusFilter(10000);
              _key.currentState?.toggle();
            },
          ),
          FloatingActionButton(
            mini: true,
            shape: const CircleBorder(),
            heroTag: '50km_filter',
            backgroundColor: circleRadiusMeters == 50000 ? Colors.blue : null,
            child: Text('50km', style: TextStyle(fontSize: 10)),
            onPressed: () {
              _updateRadiusFilter(50000);
              _key.currentState?.toggle();
            },
          ),
        ],
      ),
    );
  }
}

class CaretakerDetailView extends StatelessWidget {
  final Caretaker caretaker;
  final LatLng currentLocation;
  final Child? child;
  final Parent? parent;

  final FirestoreService firestoreService = FirestoreService();

  CaretakerDetailView({
    Key? key,
    required this.caretaker,
    required this.currentLocation,
    this.child,
    this.parent,
  }) : super(key: key);

  final parentController = FirestoreService();
  final caretakerController = CaretakerController();

  Future<void> _launchMapsDirections(BuildContext context) async {
    final url =
        'https://www.openstreetmap.org/directions?from=${currentLocation.latitude},${currentLocation.longitude}&to=${caretaker.location.latitude},${caretaker.location.longitude}';
    debugPrint(url);
    try {
      showDialog(context: context, builder: (_) => MapsWebView(url: url));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
    }
  }

  Future<void> _launchPhoneCall(BuildContext context) async {
    final url = 'tel:${caretaker.phone}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not make a call')));
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final String subject = 'Inquiry about Caretaker Services';
    final String body = child != null
        ? 'I am inquiring about caretaker services for ${child!.name}.'
        : 'I am inquiring about caretaker services.';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: caretaker.email,
      queryParameters: {'subject': subject, 'body': body},
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open email')));
    }
  }

  Future<void> _applyForCaretaker(
    BuildContext context,
    Child child,
    Parent parent,
  ) async {
    try {
      await parentController.applyCaretaker(caretaker.id, child, parent);

      if (context.mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          title: 'Application Submitted',
          desc:
              'Your application for ${child.name} has been submitted to ${caretaker.name}. Wait for your application result.',
          btnOk: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ).show();
      }
      await parentController.insertMessage('Wait for approval',
          'Your child application for ${child.name} has been submitted to ${caretaker.name}. Wait for your application result.');
      await caretakerController.insertMessageP(
          'Wait for your approval',
          'Request approval from child application; ${child.name}. Please decide.',
          caretaker.id);
    } catch (e) {
      if (context.mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          title: 'Application Error',
          desc: 'Error submitting application: ${e.toString()}',
          btnOk: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ).show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate distance
    final double distance = _calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      caretaker.location.latitude,
      caretaker.location.longitude,
    );

    void showChildSelectionDialog(List<Child> children, Parent parent) {
      Child? selectedChild = children.isNotEmpty ? children.first : null;

      AwesomeDialog(
        context: context,
        dialogType: DialogType.question,
        title: 'Select Child',
        body: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: 200,
              width: 300,
              child: children.isEmpty
                  ? const Center(child: Text('No children available'))
                  : ListView.builder(
                      itemCount: children.length,
                      itemBuilder: (context, index) {
                        return RadioListTile<Child>(
                          title: Text(children[index].name),
                          value: children[index],
                          groupValue: selectedChild,
                          onChanged: (Child? value) {
                            setState(() {
                              selectedChild = value;
                            });
                          },
                        );
                      },
                    ),
            );
          },
        ),
        btnCancel: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        btnOk: TextButton(
          onPressed: selectedChild == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  _applyForCaretaker(
                    context,
                    selectedChild!,
                    parent,
                  );
                },
          child: const Text('Submit'),
        ),
      ).show();
    }

    var textTheme = TextTheme.of(context);
    var screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(caretaker.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map showing location
            SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: caretaker.location,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.autism.care.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: caretaker.location,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Caretaker information card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              Icons.home,
                              size: 40,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  caretaker.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  caretaker.specialization,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      // Contact information
                      Text(
                        'Contact Information',
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),

                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(caretaker.phone),
                        dense: true,
                        onTap: () => _launchPhoneCall(context),
                      ),

                      ListTile(
                        leading: const Icon(Icons.email),
                        title: Text(caretaker.email),
                        dense: true,
                        onTap: () => _launchEmail(context),
                      ),

                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(caretaker.address),
                        subtitle: Text(
                          '${distance.toStringAsFixed(1)} km away',
                        ),
                        dense: true,
                        onTap: () => _launchMapsDirections(context),
                      ),

                      const Divider(height: 24),

                      // About section
                      Text(
                        'About',
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        caretaker.description.isNotEmpty
                            ? caretaker.description
                            : 'No description available.',
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 24),

                      // Services
                      Text(
                        'Services Offered',
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      if (caretaker.services.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...caretaker.services
                                .map(
                                  (service) => LargeListTile(
                                    backgroundColor: Colors.blue[100],
                                    title:
                                        Text(service), // Service name as title
                                  ),
                                )
                                .toList(),
                          ],
                        )
                      else
                        const Text('No services listed.'),

                      const Divider(height: 24),

                      FutureBuilder<Map<String, String>>(
                        future: parentController.getWorkHours(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final workHours = snapshot.data ??
                              parentController.getDefaultWorkHours();

                          // Build a single string with all work hours
                          final hoursText = Days.values.map((day) {
                            final dayName = day.toString().split('.').last;
                            return '$dayName: ${workHours[dayName.toLowerCase()] ?? 'Closed'}';
                          }).join('\n');

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.access_time_filled,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Working From',
                                        style: textTheme.bodyLarge),
                                    Gap(10),
                                    Text(hoursText,
                                        style: textTheme.bodyMedium),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const Divider(height: 24),

                      // Images and Videos section
                      Text(
                        'Images and Videos',
                        style: textTheme.bodyLarge,
                      ),

                      const SizedBox(height: 8),

                      FutureBuilder<List<MediaItem>>(
                        future: firestoreService.getMediaItems(caretaker.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('No media items yet');
                          }

                          final mediaItems = snapshot.data!;
                          final images = mediaItems
                              .where((item) => item.type == MediaType.image)
                              .toList();
                          final videos = mediaItems
                              .where((item) => item.type == MediaType.video)
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Videos Carousel (if any)
                              if (videos.isNotEmpty) ...[
                                SizedBox(
                                  height: 180,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: videos.length,
                                    itemBuilder: (context, index) {
                                      return VideoPlayerWidget(
                                          videoUrl: videos[index].url);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Images Grid (if any)
                              if (images.isNotEmpty) ...[
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: images.length,
                                  itemBuilder: (context, index) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        images[index].url,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                      ),
                                    );
                                  },
                                ),
                              ],

                              // Fallback if no media (shouldn't happen due to earlier check)
                              if (images.isEmpty && videos.isEmpty)
                                const Center(child: Text('No media available')),
                            ],
                          );
                        },
                      ),

                      const Divider(height: 24),

                      // Images and Videos section
                      Text(
                        'Reviews',
                        style: textTheme.bodyLarge,
                      ),

                      ReviewSection(
                        caretakerId: caretaker.id,
                        currentUserId: parent!.id,
                        currentUserName: parent!.name,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                  onPressed: () => _launchMapsDirections(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Apply'),
                  onPressed: () async {
                    final parent = await parentController.getParent();
                    final children =
                        await parentController.getChildrenByParent();

                    if (children.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You have no registered children'),
                        ),
                      );
                      return;
                    }

                    if (children.length == 1) {
                      // If only one child, apply directly
                      _applyForCaretaker(context, children.first, parent!);
                    } else {
                      // If multiple children, show dialog to select
                      showChildSelectionDialog(children, parent!);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Calculate distance in kilometers between two geographical points
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = (1 - cos(dLat)) / 2 +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (1 - cos(dLon)) /
            2;

    return earthRadius * 2 * asin(sqrt(a));
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}

class ParentsAutismCenter extends StatelessWidget {
  const ParentsAutismCenter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CaretakerMapView();
  }
}
