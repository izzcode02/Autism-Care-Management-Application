import 'dart:async';
import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:autism_care_management_application/screen/parents/model/provider/child_provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentsAttendance extends StatefulWidget {
  const ParentsAttendance({super.key});
  @override
  State<ParentsAttendance> createState() => _ParentsAttendanceState();
}

class _ParentsAttendanceState extends State<ParentsAttendance>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  DateTime _currentTime = DateTime.now();
  bool _isClockedIn = false;
  List<Map<String, dynamic>> _attendanceHistory = [];
  Timer? _timer;
  Timer? _locationTimer;
  late TabController _tabController;
  bool skeletonLoading = true;

  Position? _currentPosition;
  String _currentLocationText = 'Getting location...';
  String _distanceText = 'Calculating distance...';
  bool _isAtDestination = false;
  final parentController = FirestoreService();
  bool _isLate = false;
  bool _isWithinWorkingHours = false;
  bool _hasSubmittedReason = false;
  String? _submittedReason;
  bool _canClockIn = false;
  bool _canClockOut = false;
  bool _alreadyClockedInToday = false;
  bool _alreadyClockedOutToday = false;

  // Real location data from Firestore
  Map<String, dynamic>? _caretakerData;
  double? _targetLatitude;
  double? _targetLongitude;
  String _targetLocationName = 'Loading...';
  String _targetAddress = 'Loading address...';
  Map<String, String>? _workHours;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    var child = childProvider.selectedChild;

    if (childProvider.selectedChild == null) {
      if (mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          title: 'No Child Selected',
          desc: 'Please select a child first',
          dismissOnTouchOutside: false,
          dismissOnBackKeyPress: false,
          btnOkOnPress: () {
            Navigator.pop(context);
          },
          btnOkText: 'Close',
        ).show();
        setState(() => isLoading = false);
      }
      return;
    } else if (child!.autismCentreName == null) {
      if (mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          title: 'No Autism Centre',
          desc: 'Please find and apply autism centre first',
          dismissOnTouchOutside: false,
          dismissOnBackKeyPress: false,
          btnOkOnPress: () {
            Navigator.pop(context);
          },
          btnOkText: 'Close',
        ).show();
        setState(() => isLoading = false);
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      // Get caretaker data from Firestore
      final caretakerData = await parentController.getAttendanceLocation(
        childProvider.selectedChild!.caretakerId,
      );
      setState(() {
        _caretakerData = caretakerData;
        _targetLatitude = caretakerData['location']?['latitude'];
        _targetLongitude = caretakerData['location']?['longitude'];
        _targetLocationName = caretakerData['name'] ?? 'Attendance Location';
        _targetAddress = caretakerData['address'] ?? 'Address not available';
        _workHours = Map<String, String>.from(caretakerData['workHours'] ?? {});
      });

      print('Workhour: ${_workHours.toString()}');

      // Load attendance history and check today's records
      await _loadAttendanceHistory();
      await _checkTodaysAttendance(childProvider.selectedChild!.caretakerId);

      // Initialize location after getting target coordinates
      await _initializeLocation();
      _startLocationUpdates();

      // Check working hours
      _checkWorkingHours();

      // Stop skeleton loading
      if (mounted) {
        setState(() {
          skeletonLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing data: ${e.toString()}')),
        );
      }
      setState(() {
        skeletonLoading = false;
        _targetLocationName = 'Error loading location';
        _targetAddress = 'Could not load address';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _checkTodaysAttendance(String caretakerId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('caretaker')
          .doc(caretakerId)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay)
          .get();

      setState(() {
        _alreadyClockedInToday =
            snapshot.docs.any((doc) => doc['isClockedIn'] == true);
        _alreadyClockedOutToday =
            snapshot.docs.any((doc) => doc['isClockedIn'] == false);
        _isClockedIn = _alreadyClockedInToday && !_alreadyClockedOutToday;
      });
    } catch (e) {
      print('Error checking today\'s attendance: $e');
    }
  }

  void _checkWorkingHours() {
    if (_workHours == null) {
      setState(() {
        _isWithinWorkingHours = false;
        _isLate = false;
        _canClockIn = false;
        _canClockOut = false;
      });
      return;
    }

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday).toLowerCase();
    final workHours = _workHours![dayName];

    if (workHours == null || workHours == 'Closed') {
      setState(() {
        _isWithinWorkingHours = false;
        _isLate = false;
        _canClockIn = false;
        _canClockOut = false;
      });
      return;
    }

    try {
      final parts = workHours.split(' - ');
      if (parts.length != 2) {
        setState(() {
          _isWithinWorkingHours = false;
          _isLate = false;
          _canClockIn = false;
          _canClockOut = false;
        });
        return;
      }

      final startTime = _parseTimeString(parts[0]);
      final endTime = _parseTimeString(parts[1]);

      // Clock-in window: 30 mins before to 30 mins after start time
      final clockInStart = startTime.subtract(Duration(minutes: 30));
      final clockInEnd = startTime.add(Duration(minutes: 30));

      // Clock-out window: 30 mins before to 30 mins after end time
      final clockOutStart = endTime.subtract(Duration(minutes: 30));
      final clockOutEnd = endTime.add(Duration(minutes: 30));

      final canClockIn = now.isAfter(clockInStart) &&
          now.isBefore(clockInEnd) &&
          !_alreadyClockedInToday;
      final canClockOut = now.isAfter(clockOutStart) &&
          now.isBefore(clockOutEnd) &&
          _alreadyClockedInToday &&
          !_alreadyClockedOutToday;

      setState(() {
        _isWithinWorkingHours = now.isAfter(startTime) && now.isBefore(endTime);
        _isLate = now.isAfter(startTime.add(Duration(minutes: 30))) &&
            now.isBefore(endTime);
        _canClockIn = canClockIn;
        _canClockOut = canClockOut;
      });
    } catch (e) {
      setState(() {
        _isWithinWorkingHours = false;
        _isLate = false;
        _canClockIn = false;
        _canClockOut = false;
      });
    }
  }

  DateTime _parseTimeString(String timeStr) {
    final now = DateTime.now();
    final timeParts = timeStr.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1].split(' ')[0]);
    final isPM = timeStr.toLowerCase().contains('pm') && hour != 12;
    final adjustedHour = isPM ? hour + 12 : hour;

    return DateTime(now.year, now.month, now.day, adjustedHour, minute);
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  Future<void> _loadAttendanceHistory() async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    if (childProvider.selectedChild == null) return;

    try {
      final history = await parentController.getAttendanceHistory();
      setState(() {
        _attendanceHistory = history;
      });
    } catch (e) {
      print('Error loading attendance history: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
          _checkWorkingHours();
        });
      }
    });
  }

  Future<void> _clockIn() async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    if (childProvider.selectedChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a child first')),
      );
      return;
    }

    if (!_isAtDestination) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must be at the attendance location to clock in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_canClockIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot clock in outside of allowed time window'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_hasSubmittedReason) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Cannot clock in after submitting a reason for absence'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentPosition != null) {
      try {
        // Get current time and convert to TimeOfDay
        final now = DateTime.now();
        final currentTimeOfDay = TimeOfDay.fromDateTime(now);

        // For clock in: pass the current time as timeClockIn, null/empty for timeClockOut
        await parentController.recordAttendance(
          currentTimeOfDay, // timeClockIn - actual clock in time
          null, // timeClockOut - null for clock in event
          true, // isClockedIn
          childProvider.selectedChild!.caretakerId,
        );

        setState(() {
          _isClockedIn = true;
          _alreadyClockedInToday = true;
        });

        await _loadAttendanceHistory();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully clocked in at ${currentTimeOfDay.format(context)}!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clock in: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait for location to be detected'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _clockOut() async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    if (childProvider.selectedChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a child first')),
      );
      return;
    }

    if (!_isAtDestination) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must be at the attendance location to clock out'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_canClockOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot clock out outside of allowed time window'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentPosition != null) {
      try {
        // Get current time and convert to TimeOfDay
        final now = DateTime.now();
        final currentTimeOfDay = TimeOfDay.fromDateTime(now);

        // For clock out: pass null for timeClockIn, current time for timeClockOut
        await parentController.recordAttendance(
          null, // timeClockIn - null for clock out event
          currentTimeOfDay, // timeClockOut - actual clock out time
          false, // isClockedIn
          childProvider.selectedChild!.caretakerId,
        );

        setState(() {
          _isClockedIn = false;
          _alreadyClockedOutToday = true;
        });

        await _loadAttendanceHistory();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully clocked out at ${currentTimeOfDay.format(context)}!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clock out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait for location to be detected'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showReasonDialog() {
    final textTheme = TextTheme.of(context);
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      body: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Text('Select Reason for Absence',
                  style: textTheme.headlineMedium),
            ),
            ListTile(
              title: Text('Child may be sick'),
              onTap: () {
                _submitLeaveReason('Child may be sick');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text('Parent excuse'),
              onTap: () {
                _submitLeaveReason('Parent excuse');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text('Other'),
              onTap: () {
                _submitLeaveReason('Other');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
      btnCancel: ElevatedButton(
        child: Text('Cancel'),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ).show();
  }

  void _submitLeaveReason(String reason) {
    if (reason.isNotEmpty) {
      setState(() {
        _hasSubmittedReason = true;
        _submittedReason = reason;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reason submitted: $reason')),
      );
    }
  }

  Future<void> _initializeLocation() async {
    if (_targetLatitude == null || _targetLongitude == null) {
      setState(() {
        _currentLocationText = 'Target location not available';
        _distanceText = 'Cannot calculate distance';
        _isAtDestination = false;
      });
      return;
    }

    try {
      Position? position =
          await parentController.getCurrentLocationForAttendance();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _currentLocationText =
              'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        });

        double distance = parentController.calculateDistanceForAttendance(
          position.latitude,
          position.longitude,
          _targetLatitude!,
          _targetLongitude!,
        );

        bool withinRange = parentController.isWithinRadius(
          position.latitude,
          position.longitude,
          _targetLatitude!,
          _targetLongitude!,
          75, // 75 meters radius
        );

        var distanceAtKm = distance / 1000;

        setState(() {
          _isAtDestination = withinRange;
          _distanceText = withinRange
              ? 'You are at the attendance location'
              : '${distanceAtKm.toStringAsFixed(2)} meters from attendance location';
        });
      } else if (mounted) {
        setState(() {
          _currentLocationText = 'Location not available';
          _distanceText = 'Cannot calculate distance';
          _isAtDestination = false;
        });
      }
    } catch (e) {
      print('Error initializing location: $e');
      if (mounted) {
        setState(() {
          _currentLocationText = 'Location error: ${e.toString()}';
          _distanceText = 'Cannot calculate distance';
          _isAtDestination = false;
        });
      }
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        _initializeLocation();
      } else {
        timer.cancel();
      }
    });
  }

  String _formatAttendanceTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final dateTime = timestamp.toDate();
    return DateFormat('MMM d, y - HH:mm').format(dateTime);
  }

  bool get _canPerformAttendanceAction {
    return _isAtDestination && !_hasSubmittedReason;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_alert),
            onPressed:
                _isLate || !_isWithinWorkingHours ? _showReasonDialog : null,
            tooltip: 'Submit reason for absence',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Sign In/Out'), Tab(text: 'Attendance History')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Sign In/Out Tab
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Gap(10),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                    ),
                    child: Skeletonizer(
                      enabled: skeletonLoading,
                      child: LargeListTile(
                        title: Center(
                          child: Text(
                            DateFormat.jm().format(_currentTime),
                            style: textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        subtitle: Center(
                          child: Text(
                            DateFormat('EEEE, MMMM d y').format(_currentTime),
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.5),
                        extraLarge: true,
                        alignLeadingOnTop: true,
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _canPerformAttendanceAction
                        ? (_isClockedIn
                            ? (_canClockOut ? _clockOut : null)
                            : (_canClockIn ? _clockIn : null))
                        : null,
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(24),
                      minimumSize: Size(250, 250),
                      backgroundColor: _canPerformAttendanceAction
                          ? (_isClockedIn
                              ? (_canClockOut ? Colors.red : Colors.grey)
                              : (_canClockIn ? Colors.green : Colors.grey))
                          : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isClockedIn ? 'Clock Out' : 'Clock In',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isAtDestination)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Move closer to location',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          if (_isClockedIn && !_canClockOut)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Clock-out window: 30 mins before/after shift end',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          if (!_isClockedIn && !_canClockIn)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Clock-in window: 30 mins before/after shift start',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          if (_hasSubmittedReason)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Reason submitted: $_submittedReason',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          if (_alreadyClockedInToday && !_isClockedIn)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Already clocked in today',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          if (_alreadyClockedOutToday)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Already clocked out today',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Skeletonizer(
                    enabled: skeletonLoading,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Card(
                            child: ListTile(
                              leading: Icon(
                                Icons.location_on,
                                color: Colors.blue,
                              ),
                              title: Text('Current Location'),
                              subtitle: Text(_currentLocationText),
                            ),
                          ),
                          SizedBox(height: 8),
                          Card(
                            child: ListTile(
                              leading:
                                  Icon(Icons.business, color: Colors.orange),
                              title: Text('Target Location'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_targetLocationName),
                                  Text(
                                    _targetAddress,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Card(
                            color: _isAtDestination
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            child: ListTile(
                              leading: Icon(
                                Icons.near_me,
                                color: _isAtDestination
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: Text('Distance Status'),
                              subtitle: Text(_distanceText),
                              trailing: _isAtDestination
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : Icon(Icons.cancel, color: Colors.red),
                            ),
                          ),
                          SizedBox(height: 8),
                          Card(
                            color: _isWithinWorkingHours
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            child: ListTile(
                              leading: Icon(
                                Icons.access_time,
                                color: _isWithinWorkingHours
                                    ? (_isLate ? Colors.orange : Colors.green)
                                    : Colors.red,
                              ),
                              title: Text('Time Status'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isWithinWorkingHours
                                        ? (_isLate
                                            ? 'Currently in shift (arrived late)'
                                            : 'Currently in shift')
                                        : 'Outside shift hours',
                                  ),
                                  if (_workHours != null)
                                    Text(
                                      'Today\'s hours: ${_workHours![_getDayName(DateTime.now().weekday).toLowerCase()] ?? 'Closed'}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: _isWithinWorkingHours
                                  ? Icon(
                                      Icons.check_circle,
                                      color: _isLate
                                          ? Colors.orange
                                          : Colors.green,
                                    )
                                  : Icon(Icons.cancel, color: Colors.red),
                            ),
                          ),
                          if (_hasSubmittedReason) ...[
                            SizedBox(height: 8),
                            Card(
                              color: Colors.orange.shade50,
                              child: ListTile(
                                leading: Icon(
                                  Icons.info,
                                  color: Colors.orange,
                                ),
                                title: Text('Submitted Reason'),
                                subtitle: Text(
                                    _submittedReason ?? 'No reason provided'),
                                trailing:
                                    Icon(Icons.warning, color: Colors.orange),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Attendance History Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _attendanceHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No attendance history yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _attendanceHistory.length,
                    itemBuilder: (context, index) {
                      final record = _attendanceHistory[index];
                      final isClockedIn = record['isClockedIn'] ?? false;
                      final timestamp = record['date'] as Timestamp?;
                      final isLate = record['isLate'] ?? false;

                      return Skeletonizer(
                        enabled: skeletonLoading,
                        child: LargeListTile(
                          title: Text(
                            '${isClockedIn ? 'Clock In' : 'Clock Out'} - ${_formatAttendanceTime(timestamp)}',
                          ),
                          subtitle: Text(
                            'Status: ${isLate ? 'Late' : 'On time'}',
                            style: TextStyle(
                              color: isLate ? Colors.orange : Colors.green,
                            ),
                          ),
                          leading: Icon(
                            isClockedIn ? Icons.login : Icons.logout,
                            color: isClockedIn ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
