import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class ChildrenRegistration extends StatefulWidget {
  const ChildrenRegistration({super.key});

  @override
  State<ChildrenRegistration> createState() => _ChildrenRegistrationState();
}

class _ChildrenRegistrationState extends State<ChildrenRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mykidController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _otherGuardianController =
      TextEditingController();
  String resultPrint = 'result';

  String? _selectedAge;
  DateTime? _birthDate;
  String? _selectedRace;
  String? _selectedReligion;
  String? _selectedCitizenship;
  String? _custodyStatus;

  bool? _autismCenter;
  String? _selectedAutismType;
  final Map<String, bool> _autismTypes = {
    'Autism Spectrum Disorder with Level 1 SCI & Level 1 RRB': false,
    'Autism Spectrum Disorder with Level 2 SCI & Level 1 RRB with ADHD': false,
    'Autism Spectrum Disorder with Level 1 SCI & Level 2 RRB with Epilepsy':
        false,
    'Tuberous Sclerosis with Autism Spectrum Disorder': false,
  };

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final textTheme = TextTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Children Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/login.png',
                height: screenSize.height * 0.25,
              ),
              Gap(10),
              _buildLabel("Child Information Details"),
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
              Gap(10),
              _buildLabel("Full Name (as in MyKid)"),
              _buildInputField(
                "Full Name (as in MyKid)",
                controller: _nameController,
              ),
              Gap(10),
              _buildLabel("MyKID/Birth Certificate Number"),
              _buildInputField(
                "MyKID/Birth Certificate Number",
                controller: _mykidController,
              ),
              Gap(10),
              _buildLabel("Age"),
              _buildDropdown(
                "Age",
                _selectedAge,
                List.generate(18, (index) => (index + 1).toString()),
              ),
              Gap(10),
              _buildLabel("Parent/Guardian Residential Address"),
              _buildInputField(
                "Parent/Guardian Residential Address",
                controller: _addressController,
                maxLines: 3,
              ),
              Gap(10),
              _buildLabel("Date of Birth"),
              _buildDateField("Date of Birth"),
              Gap(10),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown("Race", _selectedRace, [
                      'Malay',
                      'Chinese',
                      'Indian',
                      'Other',
                    ]),
                  ),
                  Gap(10),
                  Expanded(
                    child: Column(
                      children: [
                        _buildDropdown("Religion", _selectedReligion, [
                          'Islam',
                          'Buddhism',
                          'Hinduism',
                          'Christianity',
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              Gap(10),
              _buildLabel("Citizenship"),
              _buildDropdown("Citizenship", _selectedCitizenship, [
                'Citizen',
                'Non-Citizen',
              ]),
              Gap(10),
              _buildLabel(
                  "Child custody status if parents are divorced \n(If parents are married before)."),
              if (_custodyStatus == null)
                Text(
                  '* Please select custody status',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ..._buildCustodyRadioButtons(),
              _buildLabel("Have you sent your child to any Autism Center?"),
              _buildYesNoRadio(),
              Gap(10),
              _buildLabel("Types of Autism Diagnosis"),
              if (_selectedAutismType == null)
                Text(
                  '* Please select autism type',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ..._buildAutismRadio(),
              Gap(30),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text("Submit"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
      ),
    );
  }

  Widget _buildInputField(
    String label, {
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(hintText: label),
      maxLines: maxLines,
      validator: (value) =>
          value?.isEmpty ?? true ? 'This field is required' : null,
    );
  }

  Widget _buildDateField(String label) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText:
              _birthDate == null ? '* Please select date of birth' : null,
        ),
        child: Row(
          children: [
            Text(
              _birthDate != null
                  ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                  : 'Please select date',
            ),
            const Spacer(),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCustodyRadioButtons() {
    return [
      RadioListTile<String>(
        title: const Text("Not Applicable"),
        value: "Not Applicable",
        groupValue: _custodyStatus,
        onChanged: (value) => setState(() => _custodyStatus = value),
      ),
      RadioListTile<String>(
        title: const Text("Mother"),
        value: "Mother",
        groupValue: _custodyStatus,
        onChanged: (value) => setState(() => _custodyStatus = value),
      ),
      RadioListTile<String>(
        title: const Text("Father"),
        value: "Father",
        groupValue: _custodyStatus,
        onChanged: (value) => setState(() => _custodyStatus = value),
      ),
      RadioListTile<String>(
        title: const Text("Other"),
        value: "Other",
        groupValue: _custodyStatus,
        onChanged: (value) => setState(() => _custodyStatus = value),
      ),
      if (_custodyStatus == "Other")
        TextFormField(
          controller: _otherGuardianController,
          decoration: const InputDecoration(labelText: "Please specify"),
          validator: (value) =>
              _custodyStatus == "Other" && (value?.isEmpty ?? true)
                  ? 'This field is required'
                  : null,
        ),
    ];
  }

  Widget _buildYesNoRadio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: _autismCenter,
              onChanged: (value) => setState(() => _autismCenter = value),
            ),
            const Text("Yes"),
            Radio<bool>(
              value: false,
              groupValue: _autismCenter,
              onChanged: (value) => setState(() => _autismCenter = value),
            ),
            const Text("No"),
          ],
        ),
        if (_autismCenter == null)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              'Please select an option',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildAutismRadio() {
    return [
      ..._autismTypes.keys.map((String key) {
        return RadioListTile<String>(
          title: Text(key),
          value: key,
          groupValue: _selectedAutismType,
          onChanged: (String? value) {
            setState(() {
              _selectedAutismType = value;
            });
          },
        );
      }).toList(),
    ];
  }

  Widget _buildDropdown(String label, String? value, List<String> items) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: value,
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          if (label == "Age")
            _selectedAge = newValue;
          else if (label == "Race")
            _selectedRace = newValue;
          else if (label == "Religion")
            _selectedReligion = newValue;
          else if (label == "Citizenship") _selectedCitizenship = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select $label' : null,
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Additional validation for fields not covered by FormField validators
      if (_birthDate == null) {
        _showErrorDialog(message: 'Please select date of birth');
        return;
      }

      if (_custodyStatus == null) {
        _showErrorDialog(message: 'Please select custody status');
        return;
      }

      if (_autismCenter == null) {
        _showErrorDialog(message: 'Please select autism center attendance');
        return;
      }

      if (_autismCenter == true && _selectedAutismType == null) {
        _showErrorDialog(message: 'Please select autism type');
        return;
      }

      if (_custodyStatus == "Other" && _otherGuardianController.text.isEmpty) {
        _showErrorDialog(message: 'Please specify other guardian');
        return;
      }

      try {
        final result = await _firestore.registerChild(
          name: _nameController.text,
          myKid: _mykidController.text,
          age: _selectedAge ?? '0',
          address: _addressController.text,
          birthDate: _birthDate!,
          race: _selectedRace!,
          religion: _selectedReligion!,
          citizenship: _selectedCitizenship!,
          custodyStatus: _custodyStatus!,
          otherCustody:
              _custodyStatus == "Other" ? _otherGuardianController.text : null,
          hasAttendedCenter: _autismCenter!,
          autismType: _autismCenter == true ? _selectedAutismType! : 'N/A',
        );

        setState(() => resultPrint =
            result ?? 'Registration completed but no ID returned');

        if (result != null) {
          _showSuccessDialog();
          _formKey.currentState?.reset();
          setState(() {
            _birthDate = null;
            _selectedAge = null;
            _selectedRace = null;
            _selectedReligion = null;
            _selectedCitizenship = null;
            _custodyStatus = null;
            _selectedAutismType = null;
            _autismCenter = null;
            _otherGuardianController.clear();
          });
        } else {
          _showErrorDialog();
        }
      } catch (e) {
        setState(() => resultPrint = 'Error: ${e.toString()}');
        _showErrorDialog();
      }
    }
  }

  void _showSuccessDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      title: 'Success',
      desc: 'Child information saved successfully',
      btnOkOnPress: () {
        Navigator.pop(context);
      },
    ).show();
  }

  void _showErrorDialog({String message = 'Failed to save child information'}) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: 'Error',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }
}
