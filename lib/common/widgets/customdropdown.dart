import 'package:flutter/material.dart';

class CustomDropdownFormField extends StatefulWidget {
  final dynamic value;
  final List<String> items;
  final Function(dynamic) onChanged;

  const CustomDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  _CustomDropdownFormFieldState createState() =>
      _CustomDropdownFormFieldState();
}

class _CustomDropdownFormFieldState extends State<CustomDropdownFormField> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      decoration: const InputDecoration(
        border: InputBorder.none,
        filled: true, // Fill the dropdown with white color
        fillColor: Colors.white,
        hintText: "Please choose one of selection",
      ),
      borderRadius: BorderRadius.circular(10),
      value: widget.value,
      items: widget.items.map((String item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      validator: (value) {
        if (value == null) {
          return 'Please choose one of selection';
        }
        return null;
      },
      onChanged: (dynamic value) {
        setState(() {
          widget.onChanged(value);
        });
      },
    );
  }
}
