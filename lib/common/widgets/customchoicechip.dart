import 'package:flutter/material.dart';

class CustomSelectedChoiceChip extends StatefulWidget {
  final List<String> items;
  final List<String> types;
  final Function(String?) onChanged;
  final bool isRequired;
  final bool isSmallTitle;
  final String title;

  const CustomSelectedChoiceChip({
    super.key,
    required this.items,
    required this.onChanged,
    required this.title,
    this.isRequired = false,
    this.isSmallTitle = false,
    required this.types,
  });

  @override
  _CustomSelectedChoiceChipState createState() =>
      _CustomSelectedChoiceChipState();
}

class _CustomSelectedChoiceChipState extends State<CustomSelectedChoiceChip> {
  String? _selectedValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.isRequired)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              Text(widget.title, style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Center(
            child: Wrap(
              spacing: 35,
              children: widget.items
                  .map((item) => SizedBox(
                        child: ChoiceChip(
                          label: Text(
                            item,
                            style: TextStyle(
                              color: _selectedValue == item
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          selectedColor: Colors.red,
                          backgroundColor: Colors.grey[300],
                          selected: _selectedValue == item,
                          onSelected: (selected) {
                            setState(() {
                              _selectedValue = selected ? item : null;
                              widget.onChanged(_selectedValue);
                            });
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
