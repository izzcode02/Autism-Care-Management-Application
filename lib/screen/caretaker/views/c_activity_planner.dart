import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/screen/caretaker/controllers/caretaker_controller.dart';
import 'package:autism_care_management_application/screen/caretaker/model/ActivityItem.dart';
import 'package:autism_care_management_application/screen/caretaker/model/ActivityPost.dart';
import 'package:autism_care_management_application/utils/drawer_layout.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CaretakerActivity extends StatefulWidget {
  const CaretakerActivity({super.key});

  @override
  State<CaretakerActivity> createState() => _CaretakerActivityState();
}

class _CaretakerActivityState extends State<CaretakerActivity>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrawerLayout(
      title: 'Activity Planner',
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Activity Timetable'),
          Tab(text: 'Activity Post'),
        ],
      ),
      child: TabBarView(
        controller: _tabController,
        children: const [ActivityTimetable(), ActivityPostView()],
      ),
    );
  }
}

// Activity Timetable Screen
class ActivityTimetable extends StatefulWidget {
  const ActivityTimetable({super.key});

  @override
  State<ActivityTimetable> createState() => _ActivityTimetableState();
}

class _ActivityTimetableState extends State<ActivityTimetable> {
  final caretakerController = CaretakerController();
  List<ActivityItem> activities = [];
  bool isLoading = true;

  DateTime selectedDate = DateTime.now();
  final List<DateTime> weekDays = [];

  @override
  void initState() {
    super.initState();
    _generateWeekDays();
    _loadActivities();
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
    setState(() {
      isLoading = true;
    });

    try {
      final loadedActivities = await caretakerController.getActivities(
        selectedDate,
      );

      setState(() {
        activities = loadedActivities;
        // Sort activities by time before displaying
        _sortActivitiesByTime();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading activities: $e')));
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

  void _showAddEditActivityDialog({ActivityItem? activity}) {
    final bool isEditing = activity != null;
    final timeStartController = TextEditingController(
      text: isEditing ? _formatTimeOfDay(activity.startTime) : '',
    );
    final timeEndController = TextEditingController(
      text: isEditing ? _formatTimeOfDay(activity.endTime) : '',
    );
    final taskController = TextEditingController(
      text: isEditing ? activity.task : '',
    );
    final descriptionController = TextEditingController(
      text: isEditing ? activity.description : '',
    );

    TimeOfDay startTime =
        isEditing ? activity.startTime : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime =
        isEditing ? activity.endTime : const TimeOfDay(hour: 9, minute: 0);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      title: isEditing ? 'Edit Activity' : 'Add New Activity',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: timeStartController,
                decoration: const InputDecoration(labelText: 'Start Time'),
                readOnly: true,
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (picked != null) {
                    startTime = picked;
                    timeStartController.text = _formatTimeOfDay(picked);
                  }
                },
              ),
              TextFormField(
                controller: timeEndController,
                decoration: const InputDecoration(labelText: 'End Time'),
                readOnly: true,
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (picked != null) {
                    endTime = picked;
                    timeEndController.text = _formatTimeOfDay(picked);
                  }
                },
              ),
              TextFormField(
                controller: taskController,
                decoration: const InputDecoration(
                  labelText: 'Activity Name',
                ),
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Activity Description',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        if (timeStartController.text.isEmpty ||
            timeEndController.text.isEmpty ||
            taskController.text.isEmpty) {
          return;
        }

        try {
          if (isEditing) {
            await caretakerController.updateActivity(
              activity.id,
              startTime,
              endTime,
              taskController.text,
              descriptionController.text,
              selectedDate,
            );
          } else {
            await caretakerController.addActivity(
              startTime,
              endTime,
              taskController.text,
              descriptionController.text,
              selectedDate,
            );
          }

          _loadActivities(); // This will reload and sort activities
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving activity: $e')),
          );
        }
      },
      btnCancelText: 'Cancel',
      btnOkText: isEditing ? 'Update' : 'Add',
    ).show();
  }

  Future<void> _deleteActivity(String id) async {
    try {
      await caretakerController.deleteActivity(id);
      _loadActivities(); // This will reload and sort activities
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting activity: $e')));
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

  void _showAddActivityForm() {
    final List<ActivityFormRow> activityRows = [];

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      title: 'Add Activities',
      body: StatefulBuilder(
        builder: (context, setStateForm) {
          return Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  children: const [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Time',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Activity Name',
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
                    SizedBox(width: 40),
                  ],
                ),

                const SizedBox(height: 8),

                // Activity rows
                Flexible(
                  child: SingleChildScrollView(
                    child: activityRows.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 16.0,
                            ),
                            child: Text('No activities added yet'),
                          )
                        : Column(children: activityRows),
                  ),
                ),

                // Add more button
                TextButton.icon(
                  onPressed: () {
                    setStateForm(() {
                      activityRows.add(
                        ActivityFormRow(
                          onRemove: (ActivityFormRow row) {
                            setStateForm(() {
                              activityRows.remove(row);
                            });
                          },
                        ),
                      );
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add More'),
                ),
              ],
            ),
          );
        },
      ),
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        if (activityRows.isEmpty) {
          return;
        }

        bool hasError = false;
        List<Map<String, dynamic>> activitiesData = [];

        for (var row in activityRows) {
          final data = row.getData();
          if (data == null) {
            hasError = true;
            break;
          }
          activitiesData.add(data);
        }

        if (hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill all fields correctly'),
            ),
          );
          return;
        }

        try {
          await caretakerController.addMultipleActivities(
            activitiesData,
            selectedDate,
          );
          _loadActivities(); // This will reload and sort activities
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving activities: $e'),
            ),
          );
        }
      },
      btnCancelText: 'Cancel',
      btnOkText: 'Save All',
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Timetable for',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                SizedBox(width: 80),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CustomLoader())
                : activities.isEmpty
                    ? const Center(child: Text('No activities for this day'))
                    : ListView.builder(
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
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
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      activity.description,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () =>
                                            _showAddEditActivityDialog(
                                          activity: activity,
                                        ),
                                      ),
                                      IconButton(
                                        icon:
                                            const Icon(Icons.delete, size: 20),
                                        onPressed: () =>
                                            _deleteActivity(activity.id),
                                      ),
                                    ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddActivityForm,
        child: const Icon(Icons.add),
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
}

class ActivityFormRow extends StatefulWidget {
  final Function(ActivityFormRow) onRemove;

  ActivityFormRow({Key? key, required this.onRemove}) : super(key: key);

  // Add a method to access the state
  _ActivityFormRowState? get state => _state;
  _ActivityFormRowState? _state;

  // Public method to get data from the state
  Map<String, dynamic>? getData() {
    return _state?.getFormData();
  }

  @override
  State<ActivityFormRow> createState() => _ActivityFormRowState();
}

class _ActivityFormRowState extends State<ActivityFormRow> {
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();
  final taskController = TextEditingController();
  final descriptionController = TextEditingController();

  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    // Store reference to this state in the widget
    (widget as ActivityFormRow)._state = this;
  }

  @override
  void dispose() {
    // Clear reference when disposed
    (widget as ActivityFormRow)._state = null;
    super.dispose();
  }

  // Internal method to get data
  Map<String, dynamic>? getFormData() {
    if (startTimeController.text.isEmpty ||
        endTimeController.text.isEmpty ||
        taskController.text.isEmpty) {
      return null;
    }

    return {
      'startTime': startTime,
      'endTime': endTime,
      'task': taskController.text,
      'description': descriptionController.text,
    };
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${time.hourOfPeriod}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // Time
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: startTimeController,
                    decoration: const InputDecoration(
                      hintText: 'Start',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        setState(() {
                          startTime = picked;
                          startTimeController.text = _formatTimeOfDay(picked);
                        });
                      }
                    },
                  ),
                ),
                const Text(' - '),
                Expanded(
                  child: TextFormField(
                    controller: endTimeController,
                    decoration: const InputDecoration(
                      hintText: 'End',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (picked != null) {
                        setState(() {
                          endTime = picked;
                          endTimeController.text = _formatTimeOfDay(picked);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Activity Name
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextFormField(
                controller: taskController,
                decoration: const InputDecoration(
                  hintText: 'Name',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ),

          // Description
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                hintText: 'Description',
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),

          // Remove button
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => widget.onRemove(widget),
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

// Activity Post Screen
class ActivityPostView extends StatefulWidget {
  const ActivityPostView({super.key});

  @override
  State<ActivityPostView> createState() => _ActivityPostViewState();
}

class _ActivityPostViewState extends State<ActivityPostView> {
  final ImagePicker _picker = ImagePicker();
  late Future<List<ActivityPost>> _postsFuture;
  final _controller = CaretakerController();

  @override
  void initState() {
    super.initState();
    _postsFuture = _controller.getActivityPostsByCaretaker();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = _controller.getActivityPostsByCaretaker();
    });
  }

  void _showAddEditPostDialog({ActivityPost? post}) {
    final bool isEditing = post != null;
    final titleController = TextEditingController(
      text: isEditing ? post.title : '',
    );
    final descriptionController = TextEditingController(
      text: isEditing ? post.description : '',
    );

    File? selectedImage;
    String? existingImageUrl = isEditing ? post.imageUrl : null;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.bottomSlide,
      title: isEditing ? 'Edit Activity Post' : 'Create New Activity Post',
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      body: StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title*',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description*',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.photo),
                          label: const Text('Select Image'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (image != null) {
                              setState(() {
                                selectedImage = File(image.path);
                                existingImageUrl = null;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (selectedImage != null || existingImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: selectedImage != null
                                ? Image.file(
                                    selectedImage!,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    existingImageUrl!,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              onPressed: () => setState(() {
                                selectedImage = null;
                                existingImageUrl = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      btnCancelText: 'Cancel',
      btnOkText: isEditing ? 'Update' : 'Post',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        if (titleController.text.isEmpty ||
            descriptionController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill all required fields'),
            ),
          );
          return;
        }

        try {
          if (isEditing) {
            await _controller.updateActivityPost(
              post.id,
              titleController.text,
              descriptionController.text,
              selectedImage,
              existingImageUrl,
            );
          } else {
            // Get current staff info (you'll need to implement this)
            final staffId = 'current_staff_id'; // Replace with actual staff ID
            final staffName = 'Current Staff'; // Replace with actual staff name

            await _controller.createActivityPost(
              staffId,
              staffName,
              titleController.text,
              descriptionController.text,
              selectedImage,
            );
          }
          _refreshPosts();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      },
      buttonsBorderRadius: BorderRadius.circular(8),
      buttonsTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      dialogBackgroundColor: Colors.white,
      dismissOnTouchOutside: true,
    ).show();
  }

  void _confirmDeletePost(ActivityPost post) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'Delete Post',
      desc: 'Are you sure you want to delete this activity post?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        try {
          await _controller.deleteActivityPost(
            post.id,
            post.imageUrl,
          );
          _refreshPosts();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      },
      btnCancelText: 'Cancel',
      btnOkText: 'Delete',
      btnOkColor: Colors.red,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<ActivityPost>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoader());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading posts: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Text(
                'No activity posts available. Add a new post!',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshPosts();
            },
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          post.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          'Posted by ${post.staffName} • ${post.formattedDate}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddEditPostDialog(post: post);
                            } else if (value == 'delete') {
                              _confirmDeletePost(post);
                            }
                          },
                        ),
                      ),
                      if (post.hasImage)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: post.imageUrl != null
                              ? Image.network(
                                  post.imageUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  post.image!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          post.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditPostDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
