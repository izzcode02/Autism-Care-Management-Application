import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/screen/caretaker/model/NutritionItem.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:autism_care_management_application/screen/parents/model/provider/child_provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ParentsNutrition extends StatefulWidget {
  const ParentsNutrition({super.key});

  @override
  State<ParentsNutrition> createState() => _ParentsNutritionState();
}

class _ParentsNutritionState extends State<ParentsNutrition> {
  final parentController = FirestoreService();
  List<NutritionItem> nutritionItems = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  final List<DateTime> weekDays = [];

  @override
  void initState() {
    super.initState();
    _generateWeekDays();
    // Don't load data here - wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNutritionItems();
    });
  }

  Future<void> _loadNutritionItems() async {
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
      final loadedItems = await parentController.getNutritionItems(
        selectedDate,
        childProvider.selectedChild!.caretakerId,
      );

      if (mounted) {
        setState(() {
          nutritionItems = loadedItems;
          _sortNutritionItemsByTime();
        });
      }
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

  void _sortNutritionItemsByTime() {
    nutritionItems.sort((a, b) {
      final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
      final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aMinutes.compareTo(bMinutes);
    });
  }

  void _generateWeekDays() {
    final startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    weekDays.clear();
    for (int i = 0; i < 7; i++) {
      weekDays.add(startOfWeek.add(Duration(days: i)));
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _selectMonth() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (pickedDate != null && pickedDate != selectedDate && mounted) {
      setState(() {
        selectedDate = pickedDate;
        _generateWeekDays();
      });
      _loadNutritionItems();
    }
  }

  void _selectDay(DateTime day) {
    if (day != selectedDate) {
      setState(() => selectedDate = day);
      _loadNutritionItems();
    }
  }

  void _showMealDetailsDialog(NutritionItem item) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      title: item.mealName,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Icons.access_time,
                  '${_formatTimeOfDay(item.startTime)} - ${_formatTimeOfDay(item.endTime)}'),
              const SizedBox(height: 16),
              const Text('Description:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(item.mealDescription.isNotEmpty
                  ? item.mealDescription
                  : 'No description'),
            ],
          ),
        ),
      ),
      btnOkOnPress: () {},
      btnOkText: 'Close',
    ).show();
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          final day = weekDays[index];
          final isSelected = DateUtils.isSameDay(day, selectedDate);

          return GestureDetector(
            onTap: () => _selectDay(day),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFB4F19D) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('E').format(day)),
                  Text(day.day.toString()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutritionTable() {
    if (isLoading) return const Center(child: CustomLoader());

    if (nutritionItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No meal plans for this day',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: nutritionItems.length,
      itemBuilder: (context, index) {
        final item = nutritionItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatTimeOfDay(item.startTime)),
                      const Text('-'),
                      Text(_formatTimeOfDay(item.endTime)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(item.mealName),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    item.mealDescription.length > 30
                        ? '${item.mealDescription.substring(0, 30)}...'
                        : item.mealDescription,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility,
                      size: 20, color: Colors.blue),
                  onPressed: () => _showMealDetailsDialog(item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nutrition Monitor'),
        backgroundColor: const Color(0xFFB4F19D),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nutrition Plan For',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      InkWell(
                        onTap: _selectMonth,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                  DateFormat('MMMM yyyy').format(selectedDate)),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LargeListTile(
                    trailing: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Select Date'),
                    subtitle: Center(child: _buildDateSelector()),
                  ),
                ],
              ),
            ),
          ),
          // Table Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('Time',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 3,
                    child: Text('Meal',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 3,
                    child: Text('Description',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 60),
              ],
            ),
          ),
          Expanded(child: _buildNutritionTable()),
        ],
      ),
    );
  }
}
