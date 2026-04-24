import 'package:autism_care_management_application/screen/caretaker/controllers/caretaker_controller.dart';
import 'package:autism_care_management_application/screen/caretaker/model/Attendance.dart';
import 'package:autism_care_management_application/screen/caretaker/model/children_model.dart';
import 'package:autism_care_management_application/screen/caretaker/model/parents_model.dart';
import 'package:autism_care_management_application/utils/drawer_layout.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class CaretakerAttendance extends StatefulWidget {
  const CaretakerAttendance({super.key});

  @override
  State<CaretakerAttendance> createState() => _CaretakerAttendanceState();
}

class _CaretakerAttendanceState extends State<CaretakerAttendance> {
  List<Map<String, dynamic>> _childrenWithParents = [];
  DateTime _selectedDate = DateTime.now();
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final caretakerController = CaretakerController();
  String _searchQuery = '';
  bool _isLoading = false;
  Map<String, AttendanceRecord> _attendanceRecords = {}; // Add this line

  @override
  void initState() {
    super.initState();
    _fetchChildrenWithParents();
    _fetchAttendanceRecords(); // Add this line
  }

  Future<void> _fetchAttendanceRecords() async {
    try {
      final dateStr = _dateFormat.format(_selectedDate);
      final records = await caretakerController.getAttendanceForDate(dateStr);

      setState(() {
        _attendanceRecords = {
          for (var record in records) record.childId: record
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching attendance: $e')),
      );
    }
  }

  // Call this whenever the date changes
  Future<void> _onDateChanged(DateTime newDate) async {
    setState(() => _selectedDate = newDate);
    await _fetchAttendanceRecords();
  }

  Future<void> _fetchChildrenWithParents() async {
    setState(() => _isLoading = true);
    try {
      final data = await caretakerController.getChildrenWithParents();
      setState(() {
        _childrenWithParents = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching children: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAttendanceTable(List<Map<String, dynamic>> childrenList) {
    final filteredChildren = _searchQuery.isEmpty
        ? childrenList
        : childrenList.where((childData) {
            final child = childData['child'] as Child;
            final parent = childData['parent'] as Parent?;
            return child.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                child.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (parent?.name ?? '').toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );
          }).toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredChildren.isEmpty) {
      return const Center(
        child: Text(
          'No children found',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(), // No.
              1: IntrinsicColumnWidth(), // Child ID
              2: IntrinsicColumnWidth(), // Child Name
              3: IntrinsicColumnWidth(), // Parent ID
              4: IntrinsicColumnWidth(), // Parent Name
              5: IntrinsicColumnWidth(), // Clock In
              6: IntrinsicColumnWidth(), // Clock Out
              7: IntrinsicColumnWidth(), // Date
              8: IntrinsicColumnWidth(), // Actions
            },
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: [
                  _buildTableHeader('No.'),
                  _buildTableHeader('Child ID'),
                  _buildTableHeader('Child Name'),
                  _buildTableHeader('Parent ID'),
                  _buildTableHeader('Parent Name'),
                  _buildTableHeader('Clock In'),
                  _buildTableHeader('Clock Out'),
                  _buildTableHeader('Date'),
                  _buildTableHeader('Actions'),
                ],
              ),
              ...filteredChildren.asMap().entries.map(
                (entry) {
                  final index = entry.key + 1;
                  final data = entry.value;
                  final child = data['child'] as Child;
                  final parent = data['parent'] as Parent?;
                  final dateStr = _dateFormat.format(_selectedDate);

                  return TableRow(
                    children: [
                      _buildTableCell(index.toString()),
                      _buildTableCell(child.id),
                      _buildTableCell(child.name),
                      _buildTableCell(child.parentId),
                      _buildTableCell(parent?.name ?? 'N/A'),
                      _buildTableCell(
                        _attendanceRecords[child.id]?.clockIn ?? '--:--',
                      ),
                      _buildTableCell(
                        _attendanceRecords[child.id]?.clockOut ?? '--:--',
                      ),
                      _buildTableCell(dateStr),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_attendanceRecords[child.id]
                                      ?.clockIn
                                      .isEmpty ??
                                  true)
                                IconButton(
                                  icon: const Icon(Icons.login,
                                      color: Colors.blue),
                                  onPressed: () => _handleClockIn(
                                    child.id,
                                    child.name,
                                    child.parentId,
                                    parent?.name ?? 'N/A',
                                  ),
                                  tooltip: 'Clock In',
                                ),
                              if ((_attendanceRecords[child.id]
                                          ?.clockIn
                                          .isNotEmpty ??
                                      false) &&
                                  (_attendanceRecords[child.id]
                                          ?.clockOut
                                          .isEmpty ??
                                      true))
                                IconButton(
                                  icon: const Icon(Icons.logout,
                                      color: Colors.green),
                                  onPressed: () =>
                                      _handleClockOut(child.id, dateStr),
                                  tooltip: 'Clock Out',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleClockIn(
    String childId,
    String childName,
    String parentId,
    String parentName,
  ) async {
    try {
      setState(() => _isLoading = true);
      await caretakerController.addAttendance(
        context,
        childId,
        childName,
        parentId,
        parentName,
      );
      // Refresh data after successful clock-in
      await _fetchChildrenWithParents();
      await _fetchAttendanceRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clocking in: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleClockOut(String childId, String dateStr) async {
    try {
      setState(() => _isLoading = true);
      await caretakerController.clockOutAttendance(
        context,
        childId,
        dateStr,
      );
      // Refresh data after successful clock-out
      await _fetchChildrenWithParents();
      await _fetchAttendanceRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clocking out: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return DrawerLayout(
      title: "Attendance List",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text('Attendance List', style: textTheme.headlineLarge),
            ),
            Gap(15),
            // Search and date filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by child or parent name',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(_dateFormat.format(_selectedDate)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        await _onDateChanged(picked); // Changed this line
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Data table for children
            Expanded(
              child: _buildAttendanceTable(_childrenWithParents),
            ),
          ],
        ),
      ),
    );
  }
}
