import 'package:autism_care_management_application/screen/caretaker/model/ActivityItem.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:autism_care_management_application/screen/parents/model/children_model.dart';
import 'package:autism_care_management_application/screen/parents/model/provider/child_provider.dart';
import 'package:autism_care_management_application/screen/parents/views/p_activity_post.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../common/widgets/largelisttile.dart';

import 'package:intl/intl.dart';

class ParentsActivity extends StatefulWidget {
  ParentsActivity({super.key});
  @override
  State<ParentsActivity> createState() => _ParentsActivityState();
}

class _ParentsActivityState extends State<ParentsActivity> {
  final parentController = FirestoreService();
  List<ActivityItem> activities = [];
  bool isLoading = true;

  DateTime selectedDate = DateTime.now();
  final List<DateTime> weekDays = [];

  @override
  void initState() {
    super.initState();
    _generateWeekDays();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActivities();
    });
  }

  // Sort activities by start time
  void _sortActivitiesByTime() {
    activities.sort((a, b) {
      // Convert TimeOfDay to minutes for easier comparison
      final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
      final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aMinutes.compareTo(bMinutes);
    });
  }

  Future<void> _loadActivities() async {
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
            Navigator.pop(context); // Pop the current screen
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
            Navigator.pop(context); // Pop the current screen
          },
          btnOkText: 'Close',
        ).show();
        setState(() => isLoading = false);
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      //Check the backend of activity later
      final loadedActivities = await parentController.getActivities(
        selectedDate,
        childProvider.selectedChild!.caretakerId,
      );

      setState(() {
        activities = loadedActivities;
        // Sort activities by time before displaying
        _sortActivitiesByTime();
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading nutrition: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _generateWeekDays() {
    // Calculate the start of the week (Sunday)
    final DateTime startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );

    weekDays.clear();
    for (int i = 0; i < 7; i++) {
      weekDays.add(startOfWeek.add(Duration(days: i)));
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${time.hourOfPeriod}:$minute $period';
  }

  void _selectMonth() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        _generateWeekDays();
      });
      _loadActivities();
    }
  }

  void _selectDay(DateTime day) {
    setState(() {
      selectedDate = day;
    });
    _loadActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Activity Monitor'),
        backgroundColor: const Color(0xFFB4F19D),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Monitor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Navigation buttons (Read-only purpose)
            Row(
              children: [
                Expanded(
                  child: LargeListTile(
                    title: Text('Activity Post'),
                    subtitle:
                        Text('Show recent post from autism centre activity'),
                    leading: Icon(Icons.newspaper),
                    disableChevron: true,
                    onTap: () {
                      Navigator.pushNamed(context, '/parents/activity/post');
                    },
                  ),
                ),
              ],
            ),

            Gap(20),

            // Date selection header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Timetable For',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: _selectMonth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('MMMM yyyy').format(selectedDate),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Today', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _dayHeader('Sun'),
                        _dayHeader('Mon'),
                        _dayHeader('Tue'),
                        _dayHeader('Wed'),
                        _dayHeader('Thu'),
                        _dayHeader('Fri'),
                        _dayHeader('Sat'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: weekDays.map((day) {
                        return _dayItem(day);
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Table headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: const [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Time',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Activity',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 60), // Space for view action
                ],
              ),
            ),

            // Activities list (Read-only)
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : activities.isEmpty
                      ? const Center(child: Text('No activities for this day'))
                      : ListView.builder(
                          itemCount: activities.length,
                          itemBuilder: (context, index) {
                            final activity = activities[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${_formatTimeOfDay(activity.startTime)} - ${_formatTimeOfDay(activity.endTime)}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        activity.task,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        activity.description,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    // Read-only view action
                                    IconButton(
                                      icon: const Icon(Icons.visibility,
                                          size: 20, color: Colors.blue),
                                      onPressed: () =>
                                          _showActivityDetails(activity),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayHeader(String day) {
    return SizedBox(
      width: 40,
      child: Text(
        day,
        style: const TextStyle(fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _dayItem(DateTime date) {
    final bool isSelected = DateUtils.isSameDay(date, selectedDate);

    return InkWell(
      onTap: () => _selectDay(date),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : null,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          date.day.toString(),
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showActivityDetails(ActivityItem activity) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.bottomSlide,
      title: 'Activity Details',
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(
              'Time',
              '${_formatTimeOfDay(activity.startTime)} - ${_formatTimeOfDay(activity.endTime)}',
            ),
            const SizedBox(height: 8),
            _detailRow('Activity', activity.task),
            const SizedBox(height: 8),
            _detailRow('Description', activity.description),
            const SizedBox(height: 8),
            _detailRow(
              'Date',
              DateFormat('dd MMMM yyyy').format(selectedDate),
            ),
          ],
        ),
      ),
      btnOkOnPress: () {},
      btnOkText: 'Close',
      btnOkColor: Colors.blue,
      buttonsBorderRadius: BorderRadius.circular(8),
    ).show();
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
