import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/screen/caretaker/controllers/caretaker_controller.dart';
import 'package:autism_care_management_application/screen/caretaker/model/NutritionItem.dart';
import 'package:autism_care_management_application/utils/drawer_layout.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CaretakerNutrition extends StatefulWidget {
  const CaretakerNutrition({super.key});

  @override
  State<CaretakerNutrition> createState() => _CaretakerNutritionState();
}

class _CaretakerNutritionState extends State<CaretakerNutrition> {
  @override
  Widget build(BuildContext context) {
    return DrawerLayout(
      title: 'Nutrition Planner',
      child: NutritionTimetable(),
    );
  }
}

// Nutrition Timetable Screen
class NutritionTimetable extends StatefulWidget {
  const NutritionTimetable({super.key});

  @override
  State<NutritionTimetable> createState() => _NutritionTimetableState();
}

class _NutritionTimetableState extends State<NutritionTimetable> {
  final caretakerController = CaretakerController();
  List<NutritionItem> nutritionItems = [];
  bool isLoading = true;

  DateTime selectedDate = DateTime.now();
  final List<DateTime> weekDays = [];

  @override
  void initState() {
    super.initState();
    _generateWeekDays();
    _loadNutritionItems();
  }

  // Sort nutrition items by start time
  void _sortNutritionItemsByTime() {
    nutritionItems.sort((a, b) {
      // Convert TimeOfDay to minutes for easier comparison
      final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
      final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aMinutes.compareTo(bMinutes);
    });
  }

  Future<void> _loadNutritionItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedItems = await caretakerController.getNutritionItems(
        selectedDate,
      );

      setState(() {
        nutritionItems = loadedItems;
        // Sort nutrition items by time before displaying
        _sortNutritionItemsByTime();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading nutrition items: $e')),
      );
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

  void _showAddEditNutritionDialog({NutritionItem? item}) {
    final bool isEditing = item != null;
    final timeStartController = TextEditingController(
      text: isEditing ? _formatTimeOfDay(item.startTime) : '',
    );
    final timeEndController = TextEditingController(
      text: isEditing ? _formatTimeOfDay(item.endTime) : '',
    );
    final mealNameController = TextEditingController(
      text: isEditing ? item.mealName : '',
    );
    final mealDescriptionController = TextEditingController(
      text: isEditing ? item.mealDescription : '',
    );

    TimeOfDay startTime =
        isEditing ? item.startTime : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime =
        isEditing ? item.endTime : const TimeOfDay(hour: 9, minute: 0);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      width: MediaQuery.of(context).size.width * 0.9,
      body: StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Edit Meal Plan' : 'Add New Meal Plan',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: timeStartController,
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
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
                              timeStartController.text =
                                  _formatTimeOfDay(picked);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: timeEndController,
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time_filled),
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
                              timeEndController.text = _formatTimeOfDay(picked);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: mealNameController,
                  decoration: const InputDecoration(
                    labelText: 'Meal Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: mealDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Meal Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (timeStartController.text.isEmpty ||
                              timeEndController.text.isEmpty ||
                              mealNameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please fill all required fields'),
                              ),
                            );
                            return;
                          }

                          try {
                            if (isEditing) {
                              await caretakerController.updateNutritionItem(
                                item.id,
                                startTime,
                                endTime,
                                mealNameController.text,
                                mealDescriptionController.text,
                                selectedDate,
                              );
                            } else {
                              await caretakerController.addNutritionItem(
                                startTime,
                                endTime,
                                mealNameController.text,
                                mealDescriptionController.text,
                                selectedDate,
                              );
                            }

                            Navigator.of(context).pop();
                            _loadNutritionItems(); // This will reload and sort nutrition items
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error saving meal plan: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(isEditing ? 'Update' : 'Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ).show();
  }

  Future<void> _deleteNutritionItem(String id) async {
    try {
      await caretakerController.deleteNutritionItem(id);
      _loadNutritionItems(); // This will reload and sort nutrition items
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting meal plan: $e')));
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
      _loadNutritionItems();
    }
  }

  void _selectDay(DateTime day) {
    setState(() {
      selectedDate = day;
    });
    _loadNutritionItems();
  }

  void _showAddNutritionForm() {
    final List<NutritionFormRow> nutritionRows = [];

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      width: MediaQuery.of(context).size.width * 0.95,
      body: StatefulBuilder(
        builder: (context, setStateForm) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      size: 24,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Add Meal Plans',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Header row with better styling
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Meal Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Description',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Nutrition rows container
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 300,
                    minHeight: 100,
                  ),
                  child: nutritionRows.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.restaurant,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No meal plans added yet',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap "Add Meal Plan" to get started',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(children: nutritionRows),
                        ),
                ),
                const SizedBox(height: 16),

                // Add more button with better styling
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setStateForm(() {
                        nutritionRows.add(
                          NutritionFormRow(
                            onRemove: (NutritionFormRow row) {
                              setStateForm(() {
                                nutritionRows.remove(row);
                              });
                            },
                          ),
                        );
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Meal Plan'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.orange.shade300),
                      foregroundColor: Colors.orange.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nutritionRows.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please add at least one meal plan'),
                              ),
                            );
                            return;
                          }

                          bool hasError = false;
                          List<Map<String, dynamic>> nutritionData = [];

                          for (var row in nutritionRows) {
                            final data = row.getData();
                            if (data == null) {
                              hasError = true;
                              break;
                            }
                            nutritionData.add(data);
                          }

                          if (hasError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please fill all fields correctly'),
                              ),
                            );
                            return;
                          }

                          try {
                            await caretakerController.addMultipleNutritionItems(
                              nutritionData,
                              selectedDate,
                            );
                            Navigator.pop(context);
                            _loadNutritionItems(); // This will reload and sort nutrition items
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error saving meal plans: $e'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Save All'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
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
                        'Nutrition Plan For',
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
                    'Meal',
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
                : nutritionItems.isEmpty
                    ? const Center(child: Text('No meal plans for this day'))
                    : ListView.builder(
                        itemCount: nutritionItems.length,
                        itemBuilder: (context, index) {
                          final nutritionItem = nutritionItems[index];
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
                                      '${_formatTimeOfDay(nutritionItem.startTime)} - ${_formatTimeOfDay(nutritionItem.endTime)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      nutritionItem.mealName,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      nutritionItem.mealDescription,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () =>
                                            _showAddEditNutritionDialog(
                                          item: nutritionItem,
                                        ),
                                      ),
                                      IconButton(
                                        icon:
                                            const Icon(Icons.delete, size: 20),
                                        onPressed: () => _deleteNutritionItem(
                                          nutritionItem.id,
                                        ),
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
        onPressed: _showAddNutritionForm,
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

class NutritionFormRow extends StatefulWidget {
  final Function(NutritionFormRow) onRemove;

  NutritionFormRow({Key? key, required this.onRemove}) : super(key: key);

  // Add a method to access the state
  _NutritionFormRowState? get state => _state;
  _NutritionFormRowState? _state;

  // Public method to get data from the state
  Map<String, dynamic>? getData() {
    return _state?.getFormData();
  }

  @override
  State<NutritionFormRow> createState() => _NutritionFormRowState();
}

class _NutritionFormRowState extends State<NutritionFormRow> {
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();
  final mealNameController = TextEditingController();
  final mealDescriptionController = TextEditingController();

  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    // Store reference to this state in the widget
    (widget as NutritionFormRow)._state = this;
  }

  @override
  void dispose() {
    // Clear reference when disposed
    (widget as NutritionFormRow)._state = null;
    super.dispose();
  }

  // Internal method to get data
  Map<String, dynamic>? getFormData() {
    if (startTimeController.text.isEmpty ||
        endTimeController.text.isEmpty ||
        mealNameController.text.isEmpty) {
      return null;
    }

    return {
      'startTime': startTime,
      'endTime': endTime,
      'mealName': mealNameController.text,
      'mealDescription': mealDescriptionController.text,
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

          // Meal Name
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextFormField(
                controller: mealNameController,
                decoration: const InputDecoration(
                  hintText: 'Meal Name',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ),

          // Description
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: mealDescriptionController,
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
