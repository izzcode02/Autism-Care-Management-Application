import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:autism_care_management_application/screen/parents/model/user_model.dart';
import 'package:autism_care_management_application/utils/validator.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ParentsRegistration extends StatefulWidget {
  const ParentsRegistration({super.key});

  @override
  State<ParentsRegistration> createState() => _ParentsRegistrationState();
}

class _ParentsRegistrationState extends State<ParentsRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();
  final _nameController = TextEditingController();
  String? _selectedOccupation;
  String? _otherOccupation;
  bool _showOtherOccupationField = false;
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String name = '';
  String occupation = '';
  String phoneNumber = '';
  String address = '';
  String? _selectedIncome;
  String? _exactIncome; // Stores exact amount within range
  bool _showExactIncomeField = false;
  final _exactIncomeController = TextEditingController();
  String? _maritalStatus;

  final List<String> _maritalOptions = [
    'Single',
    'Married',
    'Widower',
    'Widow',
  ];

  final List<String> _incomeRanges = [
    'Below RM 1,000.00',
    'RM 1,000.00 - RM 2,999.00',
    'RM 3,000.00 - RM 4,999.00',
    'RM 5,000.00 - RM 6,999.00',
    'RM 7,000.00 - RM 9,999.00',
    'RM 10,000.00++',
  ];

  final List<String> _malaysianOccupations = [
    'Accountant',
    'Architect',
    'Bank Officer',
    'Business Owner',
    'Civil Engineer',
    'Clerk',
    'Doctor',
    'Electrician',
    'Engineer',
    'Farmer',
    'Fisherman',
    'Graphic Designer',
    'Healthcare Worker',
    'Hotel Manager',
    'IT Professional',
    'Journalist',
    'Lawyer',
    'Lecturer',
    'Mechanic',
    'Nurse',
    'Pharmacist',
    'Pilot',
    'Police Officer',
    'Real Estate Agent',
    'Sales Executive',
    'Secretary',
    'Software Developer',
    'Teacher',
    'Technician',
    'Others'
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final textTheme = TextTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Parents Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Section
              Image.asset(
                'assets/images/login.png',
                height: screenSize.height * 0.25,
              ),
              const SizedBox(height: 20),

              _buildLabel('Parents Form Registration'),

              LargeListTile(
                leading: Icon(Icons.info_outline),
                title: Text(
                  'Reminder',
                  style: textTheme.bodyLarge,
                ),
                subtitle: Text(
                  'Please fill carefully to avoid misinformation for future application autism centre.',
                  style: textTheme.bodyMedium,
                ),
              ),

              const SizedBox(height: 5),

              // Full Name Field
              _buildLabel('Full Name (as in MyKad)'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Enter full name'),
                validator: (value) =>
                    Validator.validateField(value, 'Full name'),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 15),

              // Occupation Field
              _buildLabel('Occupation'),
              DropdownButtonFormField<String>(
                value: _selectedOccupation,
                decoration: const InputDecoration(
                  hintText: 'Select your occupation',
                  border: OutlineInputBorder(),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null) {
                    return 'Please select your occupation';
                  }
                  if (value == 'Others' &&
                      (_otherOccupation == null || _otherOccupation!.isEmpty)) {
                    return 'Please specify your occupation';
                  }
                  return null;
                },
                items: _malaysianOccupations.map((String occupation) {
                  return DropdownMenuItem<String>(
                    value: occupation,
                    child: Text(occupation),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedOccupation = newValue;
                    _showOtherOccupationField = newValue == 'Others';
                    if (!_showOtherOccupationField) {
                      _otherOccupation =
                          null; // Clear other field when switching away from "Others"
                    }
                  });
                },
              ),
              if (_showOtherOccupationField) // Show only when "Others" is selected
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Please specify your occupation',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _otherOccupation = value;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (_selectedOccupation == 'Others' &&
                          (value == null || value.isEmpty)) {
                        return 'Please specify your occupation';
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 15),

              // Phone Number Field
              _buildLabel('Phone Number'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Enter phone number',
                ),
                validator: (value) => Validator.validatePhone(value),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 15),

              // Employer Address Field
              _buildLabel('Employer Address'),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter residential address',
                ),
                validator: (value) =>
                    Validator.validateField(value, 'Employer address'),
                textCapitalization: TextCapitalization.characters,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 15),

              // Monthly Income Field
              _buildLabel('Monthly Income'),
              DropdownButtonFormField<String>(
                value: _selectedIncome,
                decoration: const InputDecoration(
                  hintText: 'Select income range',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null) return 'Please select income range';
                  if (_exactIncome == null || _exactIncome!.isEmpty) {
                    return 'Please specify exact income';
                  }
                  return null;
                },
                items: _incomeRanges.map((String range) {
                  return DropdownMenuItem<String>(
                    value: range,
                    child: Text(range),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedIncome = newValue;
                    _showExactIncomeField =
                        newValue != null; // Always show for any selection
                    if (!_showExactIncomeField) _exactIncome = null;
                  });
                },
              ),

              if (_showExactIncomeField)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    controller: _exactIncomeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Exact Monthly Income (RM)',
                      border: OutlineInputBorder(),
                      prefixText: 'RM ',
                      suffixText: '.00',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter exact income';
                      }

                      final amount = double.tryParse(value);
                      if (amount == null) return 'Invalid amount';

                      // Validate against selected range
                      switch (_selectedIncome) {
                        case 'Below RM 1,000.00':
                          if (amount >= 1000)
                            return 'Must be below RM 1,000.00';
                          if (amount < 500)
                            return 'Minimum RM 500.00'; // Optional minimum
                          break;

                        case 'RM 1,000.00 - RM 2,999.00':
                          if (amount < 1000 || amount > 2999)
                            return 'Must be between RM 1,000.00-2,999.00';
                          break;

                        case 'RM 3,000.00 - RM 4,999.00':
                          if (amount < 3000 || amount > 4999)
                            return 'Must be between RM 3,000.00-4,999.00';
                          break;

                        case 'RM 5,000.00 - RM 6,999.00':
                          if (amount < 5000 || amount > 6999)
                            return 'Must be between RM 5,000.00-6,999.00';
                          break;

                        case 'RM 7,000.00 - RM 9,999.00':
                          if (amount < 7000 || amount > 9999)
                            return 'Must be between RM 7,000.00-9,999.00';
                          break;

                        case 'RM 10,000.00++':
                          if (amount < 10000)
                            return 'Must be RM 10,000.00 or more';
                          if (amount > 100000)
                            return 'Maximum RM 100,000.00'; // Optional cap
                          break;

                        default:
                          return 'Invalid income range selected';
                      }

                      return null;
                    },
                    onChanged: (value) => _exactIncome = value,
                  ),
                ),
              const SizedBox(height: 15),

              // Marital Status Dropdown
              _buildLabel('Marital Status'),
              DropdownButtonFormField<String>(
                value: _maritalStatus,
                items: _maritalOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _maritalStatus = value),
                decoration: const InputDecoration(
                  hintText: 'Select marital status',
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) =>
                    value == null ? 'Please select marital status' : null,
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    final textTheme = TextTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: textTheme.labelLarge!.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final result = await _firestore.registerParents(
        name: _nameController.text,
        occupation: _selectedOccupation == 'Others'
            ? _otherOccupation!
            : _selectedOccupation!,
        phone: _phoneController.text,
        employerAddress: _addressController.text,
        monthlyIncome: double.tryParse(_exactIncomeController.text),
        maritalStatus: _maritalStatus!,
      );

      if (result != null) {
        _showSuccessDialog();
      } else {
        _showErrorDialog();
      }
    }
  }

  void _showSuccessDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.bottomSlide,
      title: 'Success',
      desc: 'Parent information saved successfully',
      btnOkOnPress: () {
        Navigator.pop(context);
      },
      btnOkText: 'OK',
      btnOkColor: Colors.green,
    ).show();
  }

  void _showErrorDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.rightSlide,
      headerAnimationLoop: false,
      title: 'Error',
      desc: 'Failed to save parent information',
      btnOkOnPress: () => Navigator.pop(context),
      btnOkIcon: Icons.cancel,
      btnOkColor: Colors.red,
    ).show();
  }
}
