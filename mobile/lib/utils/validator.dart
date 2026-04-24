import 'package:flutter/material.dart';

class Validator {
  static String? validateEmailAddress(String? value) {
    final context = GlobalKey<NavigatorState>().currentContext;
    if (value == null || value.isEmpty) {
      return 'Please insert email address';
    }
    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(value)) {
      return 'Please follow email format ex: abc@gmail.com';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final context = GlobalKey<NavigatorState>().currentContext;

    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    // Check for common weak number patterns
    final weakNumberPatterns = [
      '0000',
      '00000',
      '000000',
      '0000000',
      '00000000',
      '1111',
      '11111',
      '111111',
      '1111111',
      '11111111',
      '1234',
      '12345',
      '123456',
      '1234567',
      '12345678',
      '4321',
      '54321',
      '654321',
      '7654321',
      '87654321',
      '987654321'
    ];

    if (RegExp(r'^[0-9]+$').hasMatch(value)) {
      if (weakNumberPatterns.any((pattern) => value.contains(pattern))) {
        return 'Sequential numbers are too easy to guess. Mix letters and symbols.';
      }
      return 'All-number passwords are weak. Add letters and symbols.';
    }

    // Check for password strength and provide suggestions
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigits = value.contains(RegExp(r'[0-9]'));
    final hasSpecialChars = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    List<String> suggestions = [];

    if (!hasUppercase) {
      suggestions.add('• At least one uppercase letter (A-Z)');
    }
    if (!hasLowercase) {
      suggestions.add('• At least one lowercase letter (a-z)');
    }
    if (!hasDigits) {
      suggestions.add('• At least one number (0-9)');
    }
    if (!hasSpecialChars) {
      suggestions.add('• At least one special character (!@#\$ etc.)');
    }

    if (suggestions.isNotEmpty) {
      return 'For a stronger password, consider adding:\n${suggestions.join('\n')}';
    }

    // Optional: Check for common weak patterns
    if (RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$')
        .hasMatch(value)) {
      return 'Password is decent but could be stronger with special characters';
    }

    if (value.toLowerCase().contains('password') ||
        RegExp(r'^[0-9]+$').hasMatch(value) ||
        RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
      return 'This password is too weak. Try mixing letters, numbers, and symbols';
    }

    return null;
  }

  static String? validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please insert $fieldName';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please insert phone number';
    }
    if (!RegExp(r'^[0-9]{9,11}$').hasMatch(value)) {
      return 'No. telefon tidak sah';
    }
    return null;
  }
}
