import 'package:flutter/material.dart';

class FieldBox extends StatefulWidget {
  const FieldBox({
    super.key,
    this.keyboardType,
    required this.validator,
    this.label,
    required this.onChanged,
    this.controller,
    this.obscureText = false,
    this.initial,
    this.prefix,
    this.suffix,
    this.lines = 1,
    this.readOnly = false,
    this.isSmallSized = false,
    this.hint,
    this.style = false,
  });

  final String? initial;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final String? label;
  final TextEditingController? controller;
  final bool obscureText;
  final Function(String value) onChanged;
  final String? prefix;
  final String? suffix;
  final String? hint;
  final int? lines;
  final bool readOnly;
  final bool isSmallSized;
  final bool style;

  @override
  State<FieldBox> createState() => _FieldBoxState();
}

class _FieldBoxState extends State<FieldBox> {
  bool _obscureText = true;

  // Toggles the password show status
  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller != null && widget.initial != null) {
      widget.controller!.text = widget.initial!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double scaleFactor = widget.isSmallSized ? 0.8 : 1.0;

    return Container(
      margin: const EdgeInsets.only(top: 20, left: 10, right: 10),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextFormField(
        initialValue: widget.controller != null ? null : widget.initial,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.keyboardType == TextInputType.emailAddress ||
                widget.obscureText
            ? TextCapitalization.none
            : TextCapitalization.characters,
        validator: widget.validator,
        controller: widget.controller,
        obscureText: widget.obscureText ? _obscureText : !_obscureText,
        minLines: widget.lines,
        maxLines: widget.lines,
        readOnly: widget.readOnly,
        enabled: !widget.readOnly,
        textInputAction: TextInputAction.next,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          fillColor: Colors.white,
          filled: true,
          alignLabelWithHint: true,
          border: InputBorder.none,
          labelText: widget.label,
          prefixText: widget.prefix,
          suffixText: widget.suffix,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          helperText: widget.hint,
          suffixIcon: widget.obscureText
              ? IconButton(
                  onPressed: _toggle,
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                )
              : null,
          contentPadding: EdgeInsets.symmetric(
              vertical: 8 * scaleFactor, horizontal: 10 * scaleFactor),
          labelStyle: TextStyle(fontSize: 16 * scaleFactor),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
