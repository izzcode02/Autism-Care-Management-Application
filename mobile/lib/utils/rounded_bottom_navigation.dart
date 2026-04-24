import 'package:flutter/material.dart';

class NavItem {
  final Widget icon;
  final String label;

  NavItem({required this.icon, required this.label});
}

class RoundedBottomNavigation extends StatefulWidget {
  final int initialIndex;
  final Function(int) onItemSelected;
  final List<NavItem> items;

  const RoundedBottomNavigation({
    Key? key,
    this.initialIndex = 0,
    required this.onItemSelected,
    required this.items,
  }) : super(key: key);

  @override
  State<RoundedBottomNavigation> createState() => _RoundedBottomNavigationState();
}

class _RoundedBottomNavigationState extends State<RoundedBottomNavigation> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFBBBBBF),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            widget.items.length,
            (index) => _buildNavItem(index),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = widget.items[index];
    final isSelected = index == _selectedIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        widget.onItemSelected(index);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? const Color(0xFF10151C) : const Color(0xFFE5E5E5),
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(
              color: isSelected ? Colors.white : Colors.black,
              size: 26,
            ),
            child: item.icon,
          ),
        ),
      ),
    );
  }
}