import 'package:flutter/material.dart';

Future<bool?> showYesNoDialog({
  required BuildContext context,
  required String title,
  required String message,
  IconData? icon,
  String? positiveButton,
  String? negativeButton,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        icon: icon != null ? Icon(icon, size: 72) : null,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            // child: Text(negativeButton ?? AppLocalizations.of(context)!.no),
            child: Text(negativeButton ?? 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(positiveButton ?? 'Yes'),
          ),
        ],
      );
    },
  );
}
