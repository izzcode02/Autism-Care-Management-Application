import 'package:flutter/material.dart';

class NextButton extends StatefulWidget {
  const NextButton({
    super.key,
    this.child,
    required this.valueColor,
    this.nameButton,
    required this.routeName,
  });

  final Widget? child;
  final String routeName;
  final int valueColor;
  final String? nameButton;

  @override
  State<NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<NextButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(300, 50)),
        padding: WidgetStateProperty.all<EdgeInsets>(
          const EdgeInsets.symmetric(vertical: 17),
        ),
        backgroundColor: WidgetStateProperty.all<Color>(
          Color(widget.valueColor),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Color(widget.valueColor)),
          ),
        ),
      ),
      //onPressed: login,
      onPressed: () {
        setState(() {});
        Navigator.pushNamed(context, widget.routeName);
      },
      child: Text(
        widget.nameButton!.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class SubmitButton extends StatefulWidget {
  SubmitButton({
    super.key,
    this.icon,
    required this.onPressed,
    required this.text,
    required this.color,
  });

  final VoidCallback? onPressed;
  final String text;
  final Color color;
  Icon? icon;

  @override
  _SubmitButtonState createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(300, 50)),
          padding: WidgetStateProperty.all<EdgeInsets>(
            const EdgeInsets.symmetric(vertical: 17),
          ),
          backgroundColor: WidgetStateProperty.all<Color>(widget.color),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: widget.color),
            ),
          ),
        ),
        onPressed: widget.onPressed,
        icon: widget.icon,
        label: Text(
          textAlign: TextAlign.center,
          widget.text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
