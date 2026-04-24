import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:autism_care_management_application/screen/parents/model/children_model.dart';
import 'package:autism_care_management_application/screen/parents/model/parents_model.dart';
import 'package:autism_care_management_application/screen/parents/model/user_model.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  bool showMoreInfo = false;
  // Keys for refreshing Futures
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Use ValueNotifier to trigger rebuilds
  ValueNotifier<int>? _refreshTrigger;

  @override
  void initState() {
    super.initState();
    _refreshTrigger = ValueNotifier<int>(0);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTrigger?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _triggerRefresh();
    }
  }

  // Method to trigger refresh
  void _triggerRefresh() {
    setState(() {
      _refreshTrigger?.value++;
    });
  }

  // Load data based on refresh trigger
  Future<Users?> _loadUserData() async {
    final firestore = FirestoreService();
    return await firestore.getCurrentUserF(context);
  }

  Future<Parent?> _loadParentData() async {
    final firestore = FirestoreService();
    return await firestore.getParent();
  }

  Future<List<Child>> _loadChildrenData() async {
    final firestore = FirestoreService();
    return await firestore.getChildrenByParent();
  }

  Future<void> _refreshData() async {
    _triggerRefresh();
  }

  Future deleteChildData(String childId) async {
    final firestore = FirestoreService();
    try {
      await firestore.deleteChild(childId);
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Child deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Trigger refresh after successful deletion
        _triggerRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting child: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Navigate with auto-refresh on return
  void _navigateAndRefresh(String routeName) {
    Navigator.pushNamed(context, routeName).then((_) {
      // Always refresh when returning from any navigation
      _triggerRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final textTheme = TextTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Profile'), elevation: 0),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: ValueListenableBuilder<int>(
            valueListenable: _refreshTrigger as ValueNotifier<int>,
            builder: (context, trigger, child) {
              return FutureBuilder<Users?>(
                key: ValueKey(trigger), // Force rebuild with new key
                future: _loadUserData(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CustomLoader());
                  }

                  if (userSnapshot.hasError || !userSnapshot.hasData) {
                    return Center(child: Text('Error: ${userSnapshot.error}'));
                  }

                  final Users? user = userSnapshot.data;

                  return Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            color: Color(0xFFB4F19D),
                            width: screenSize.width,
                            height: screenSize.height * 0.25,
                          ),
                          CircleAvatar(
                            radius: 50,
                            foregroundImage:
                                AssetImage('assets/icons/photo.png'),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Parents Information',
                                  style: textTheme.bodyLarge,
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    _navigateAndRefresh(
                                        '/parents/profile/register-parents');
                                  },
                                  label: Text('Update'),
                                  icon: Icon(Icons.edit),
                                ),
                              ],
                            ),
                            Container(
                              width: screenSize.width,
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white70,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Profile Name:',
                                      style: textTheme.bodyLarge),
                                  Text(
                                    user?.name ?? 'N/A',
                                    style: textTheme.bodyMedium,
                                  ),
                                  Gap(5),
                                  Text('Email', style: textTheme.bodyLarge),
                                  Text(
                                    user?.email ?? 'N/A',
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Gap(5),
                            Row(
                              children: [
                                Expanded(child: Divider(height: 15)),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      showMoreInfo = !showMoreInfo;
                                    });
                                  },
                                  child: Text(
                                    showMoreInfo
                                        ? "Hide Information"
                                        : "More Information",
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                                Expanded(child: Divider(height: 15)),
                              ],
                            ),

                            // Additional Information (Visible when _showMoreInfo is true)
                            Visibility(
                              visible: showMoreInfo,
                              child: FutureBuilder<Parent?>(
                                key: ValueKey('parent_$trigger'),
                                future: _loadParentData(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CustomLoader();
                                  }
                                  if (snapshot.hasError) {
                                    return Text('Error loading data');
                                  }

                                  final parent = snapshot.data;

                                  return Container(
                                    width: screenSize.width,
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: Colors.white70,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Phone Number:',
                                          style: textTheme.bodyLarge,
                                        ),
                                        Text(
                                          parent?.phone ?? "No information",
                                          style: textTheme.bodyMedium,
                                        ),
                                        Gap(5),
                                        Text(
                                          'Occupation:',
                                          style: textTheme.bodyLarge,
                                        ),
                                        Text(
                                          parent?.occupation ??
                                              "No information",
                                          style: textTheme.bodyMedium,
                                        ),
                                        Gap(5),
                                        Text(
                                          'Employer Address:',
                                          style: textTheme.bodyLarge,
                                        ),
                                        Text(
                                          parent?.employerAddress ??
                                              "No information",
                                          style: textTheme.bodyMedium,
                                        ),
                                        Gap(5),
                                        Text(
                                          'Monthly Income:',
                                          style: textTheme.bodyLarge,
                                        ),
                                        Text(
                                          parent?.monthlyIncome != null
                                              ? 'RM ${parent?.monthlyIncome?.toStringAsFixed(2)}'
                                              : 'N/A',
                                          style: textTheme.bodyMedium,
                                        ),
                                        Gap(5),
                                        Text(
                                          'Marital Status:',
                                          style: textTheme.bodyLarge,
                                        ),
                                        Text(
                                          parent?.maritalStatus ??
                                              "No information",
                                          style: textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Gap(5),
                            Divider(height: 15),
                            Gap(5),

                            // Conditional rendering of Children Information section
                            FutureBuilder<Parent?>(
                              key: ValueKey('parent_check_$trigger'),
                              future: _loadParentData(),
                              builder: (context, parentSnapshot) {
                                if (parentSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(child: CustomLoader());
                                }

                                final parent = parentSnapshot.data;
                                final bool isParentInfoComplete =
                                    parent != null &&
                                        parent.phone != null &&
                                        parent.occupation != null;

                                if (!isParentInfoComplete) {
                                  // Parent information is not available - show notice
                                  return Container(
                                    width: screenSize.width,
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.amber.shade100,
                                      border: Border.all(
                                        color: Colors.amber.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.amber.shade800,
                                            ),
                                            Gap(10),
                                            Text(
                                              'Complete Your Profile',
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Gap(10),
                                        Text(
                                          'Please complete your parent information before adding children details.',
                                          style: textTheme.bodyMedium,
                                        ),
                                        Gap(15),
                                        Center(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              _navigateAndRefresh(
                                                  '/parents/profile/register-parents');
                                            },
                                            icon: Icon(Icons.edit),
                                            label: Text('Update Parent Info'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.amber.shade600,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  // Parent information is available - show children section
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Children Information',
                                            style: textTheme.bodyLarge,
                                          ),
                                          TextButton.icon(
                                            onPressed: () {
                                              _navigateAndRefresh(
                                                  '/parents/profile/register-children');
                                            },
                                            label: Text('Add child'),
                                            icon: Icon(Icons.add_box_outlined),
                                          ),
                                        ],
                                      ),
                                      FutureBuilder<List<Child>>(
                                        key: ValueKey('children_$trigger'),
                                        future: _loadChildrenData(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Skeletonizer(
                                              child: LargeListTile(
                                                backgroundColor: Colors.white,
                                                leading: CircleAvatar(
                                                  child: Icon(Icons.child_care),
                                                ),
                                                title: Text("child.name"),
                                                subtitle: Text(
                                                  "No centre. Please register centre for your children",
                                                ),
                                              ),
                                            );
                                          }
                                          if (snapshot.hasError) {
                                            return Text(
                                                "Error: ${snapshot.error}");
                                          }

                                          final children = snapshot.data ?? [];

                                          if (children.isEmpty) {
                                            return Container(
                                              width: screenSize.width,
                                              padding: EdgeInsets.all(15),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  10,
                                                ),
                                                color: Colors.white70,
                                              ),
                                              child: Center(
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      Icons.child_care_outlined,
                                                      size: 48,
                                                      color: Colors.grey,
                                                    ),
                                                    Gap(10),
                                                    Text(
                                                      "No children registered yet",
                                                      style: textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                        color: Colors
                                                            .grey.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }

                                          return Column(
                                            children: children
                                                .map(
                                                  (child) => LargeListTile(
                                                    backgroundColor:
                                                        Colors.white70,
                                                    leading: CircleAvatar(
                                                      child: Icon(
                                                        Icons.child_care,
                                                      ),
                                                    ),
                                                    title: Text(child.name),
                                                    subtitle: Text(
                                                      child.autismCentreName ??
                                                          "No centre. Please register centre for your children",
                                                    ),
                                                    trailing: Row(
                                                      children: [
                                                        IconButton(
                                                          onPressed: () {
                                                            // Show confirmation dialog before deleting
                                                            _showDeleteConfirmation(
                                                                child);
                                                          },
                                                          icon: Icon(
                                                            Icons.delete,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                        IconButton(
                                                          onPressed: () =>
                                                              showEditChildDialog(
                                                            context,
                                                            child,
                                                          ),
                                                          icon: Icon(
                                                            Icons.edit,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    onTap: () {},
                                                  ),
                                                )
                                                .toList(),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Child child) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: 'Delete Child',
      desc: 'Are you sure you want to delete ${child.name}?',
      btnCancelOnPress: () {
        // Dialog automatically closes
      },
      btnOkOnPress: () {
        deleteChildData(child.id);
      },
      btnCancelText: 'Cancel',
      btnCancelColor: Colors.lightGreen,
      btnOkText: 'Delete',
      btnOkColor: Colors.red,
    ).show();
  }

  Future<void> showEditChildDialog(BuildContext context, Child child) async {
    final _formKey = GlobalKey<FormState>();
    final _firestore = FirestoreService();

    // Controllers initialized with child data
    final nameController = TextEditingController(text: child.name);
    final mykidController = TextEditingController(text: child.myKid);
    final addressController = TextEditingController(text: child.address);
    final otherGuardianController = TextEditingController(
      text: child.otherCustody ?? '',
    );

    String selectedAge = child.age.toString();
    DateTime birthDate = child.birthDate;
    String selectedRace = child.race;
    String selectedReligion = child.religion;
    String selectedCitizenship = child.citizenship;
    String custodyStatus = child.custodyStatus;
    bool autismCenter = child.hasAttendedCenter;
    String selectedAutismType = child.autismType;

    final Map<String, bool> autismTypes = {
      'Autism Spectrum Disorder with Level 1 SCI & Level 1 RRB': false,
      'Autism Spectrum Disorder with Level 2 SCI & Level 1 RRB with ADHD':
          false,
      'Autism Spectrum Disorder with Level 1 SCI & Level 2 RRB with Epilepsy':
          false,
      'Tuberous Sclerosis with Autism Spectrum Disorder': false,
    };

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Edit Child Information'),
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final updatedChild = child.copyWith(
                      name: nameController.text,
                      myKid: mykidController.text,
                      age: num.tryParse(selectedAge) ?? child.age,
                      address: addressController.text,
                      birthDate: birthDate,
                      race: selectedRace,
                      religion: selectedReligion,
                      citizenship: selectedCitizenship,
                      custodyStatus: custodyStatus,
                      otherCustody: custodyStatus == "Other"
                          ? otherGuardianController.text
                          : null,
                      hasAttendedCenter: autismCenter,
                      autismType: selectedAutismType,
                    );

                    debugPrint('Updated Child:');
                    debugPrint('Name: ${updatedChild.name}');
                    debugPrint('MyKid: ${updatedChild.myKid}');
                    debugPrint('Age: ${updatedChild.age}');
                    debugPrint('Address: ${updatedChild.address}');
                    debugPrint('Birth Date: ${updatedChild.birthDate}');
                    debugPrint('Race: ${updatedChild.race}');
                    debugPrint('Religion: ${updatedChild.religion}');
                    debugPrint('Citizenship: ${updatedChild.citizenship}');
                    debugPrint('Custody Status: ${updatedChild.custodyStatus}');
                    debugPrint('Other Custody: ${updatedChild.otherCustody}');
                    debugPrint(
                        'Has Attended Center: ${updatedChild.hasAttendedCenter}');
                    debugPrint('Autism Type: ${updatedChild.autismType}');

                    try {
                      await _firestore.updateChild(updatedChild);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Child updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Trigger refresh after successful update
                      _triggerRefresh();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating child: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLabel("Full Name (as in MyKid)", context),
                  _buildInputField(
                    "Full Name (as in MyKid)",
                    nameController,
                  ),
                  _buildLabel("MyKID/Birth Certificate Number", context),
                  _buildInputField(
                    "MyKID/Birth Certificate Number",
                    mykidController,
                  ),
                  _buildLabel("Age", context),
                  _buildDropdown(
                    "Age",
                    selectedAge,
                    List.generate(18, (index) => (index + 1).toString()),
                    (value) => selectedAge = value!,
                    context,
                  ),
                  _buildLabel(
                    "Parent/Guardian Residential Address",
                    context,
                  ),
                  _buildInputField(
                    "Parent/Guardian Residential Address",
                    addressController,
                    maxLines: 3,
                  ),
                  _buildLabel("Date of Birth", context),
                  _buildDateField(
                    birthDate,
                    (date) => birthDate = date!,
                    context,
                  ),
                  Gap(5),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          "Race",
                          selectedRace,
                          ['Malay', 'Chinese', 'Indian', 'Other'],
                          (value) => selectedRace = value!,
                          context,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDropdown(
                          "Religion",
                          selectedReligion,
                          ['Islam', 'Buddhism', 'Hinduism', 'Christianity'],
                          (value) => selectedReligion = value!,
                          context,
                        ),
                      ),
                    ],
                  ),
                  _buildLabel("Citizenship", context),
                  _buildDropdown(
                    "Citizenship",
                    selectedCitizenship,
                    ['Citizen', 'Non-Citizen'],
                    (value) => selectedCitizenship = value!,
                    context,
                  ),
                  _buildLabel(
                    "Child custody status if parents are divorced",
                    context,
                  ),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text("-"),
                            value: "-",
                            groupValue: custodyStatus,
                            onChanged: (value) =>
                                setState(() => custodyStatus = value!),
                          ),
                          RadioListTile<String>(
                            title: const Text("Mother"),
                            value: "Mother",
                            groupValue: custodyStatus,
                            onChanged: (value) =>
                                setState(() => custodyStatus = value!),
                          ),
                          RadioListTile<String>(
                            title: const Text("Father"),
                            value: "Father",
                            groupValue: custodyStatus,
                            onChanged: (value) =>
                                setState(() => custodyStatus = value!),
                          ),
                          RadioListTile<String>(
                            title: const Text("Other"),
                            value: "Other",
                            groupValue: custodyStatus,
                            onChanged: (value) =>
                                setState(() => custodyStatus = value!),
                          ),
                          if (custodyStatus == "Other")
                            _buildInputField(
                              "Please specify",
                              otherGuardianController,
                            ),
                        ],
                      );
                    },
                  ),
                  _buildLabel(
                    "Have you sent your child to any Autism Center?",
                    context,
                  ),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: autismCenter,
                            onChanged: (value) =>
                                setState(() => autismCenter = value!),
                          ),
                          const Text("Yes"),
                          Radio<bool>(
                            value: false,
                            groupValue: autismCenter,
                            onChanged: (value) =>
                                setState(() => autismCenter = value!),
                          ),
                          const Text("No"),
                        ],
                      );
                    },
                  ),
                  _buildLabel("Types of Autism Diagnosis", context),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Column(
                        children: autismTypes.keys.map((String key) {
                          return RadioListTile<String>(
                            title: Text(key),
                            value: key,
                            groupValue: selectedAutismType,
                            onChanged: (String? value) {
                              setState(
                                () => selectedAutismType = value!,
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildLabel(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16),
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
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      maxLines: maxLines,
      validator: (value) =>
          value?.isEmpty ?? true ? 'This field is required' : null,
    );
  }

  Widget _buildDateField(
    DateTime initialDate,
    ValueChanged<DateTime?> onDateChanged,
    BuildContext context,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onDateChanged(date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: "Date of Birth"),
        child: Row(
          children: [
            Text(DateFormat('dd/MM/yyyy').format(initialDate)),
            const Spacer(),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    BuildContext context,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: value,
      items: items.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select $label' : null,
    );
  }
}
