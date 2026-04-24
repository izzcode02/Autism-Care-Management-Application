import 'package:flutter/material.dart';

class DatePickerTextField extends StatefulWidget {
  final ValueChanged<String>? onDateSelected;
  final String? initialDate;

  const DatePickerTextField({
    super.key,
    this.onDateSelected,
    this.initialDate,
  });

  @override
  _DatePickerTextFieldState createState() => _DatePickerTextFieldState();
}

class _DatePickerTextFieldState extends State<DatePickerTextField> {
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.initialDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      final dateString = "${pickedDate.toLocal()}".split(' ')[0]; // YYYY-MM-DD
      setState(() {
        _dateController.text = dateString;
      });
      widget.onDateSelected?.call(dateString);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      child: TextField(
        controller: _dateController,
        readOnly: true,
        onTap: () => _selectDate(context),
        decoration: InputDecoration(
          hintText: 'Filter date',
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }
}