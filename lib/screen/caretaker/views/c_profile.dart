import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/common/widgets/mapdialogview.dart';
import 'package:autism_care_management_application/common/widgets/video_player_widget.dart';
import 'package:autism_care_management_application/screen/caretaker/controllers/caretaker_controller.dart';
import 'package:autism_care_management_application/screen/caretaker/controllers/location_controller.dart';
import 'package:autism_care_management_application/screen/caretaker/model/caretaker_model.dart';
import 'package:autism_care_management_application/screen/caretaker/model/Staff.dart';
import 'package:autism_care_management_application/screen/caretaker/model/media_model.dart';
import 'package:autism_care_management_application/utils/drawer_layout.dart';
import 'package:autism_care_management_application/utils/validator.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class CaretakerProfile extends StatefulWidget {
  const CaretakerProfile({super.key});

  @override
  State<CaretakerProfile> createState() => _CaretakerProfileState();
}

enum Days { Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday }

class _CaretakerProfileState extends State<CaretakerProfile>
    with SingleTickerProviderStateMixin {
  final CaretakerController caretakerController = CaretakerController();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final _passwordController = TextEditingController();
  String _searchQuery = '';

  //UPDATE PERSONALIZATION DIALOG
  Future<void> _showEditDialog({
    required BuildContext context,
    required String title,
    required String fieldName,
    required String currentValue,
    required Function(String) onSave,
    int maxLines = 1,
  }) async {
    final textController = TextEditingController(text: currentValue);
    final textTheme = Theme.of(context).textTheme;
    final formKey = GlobalKey<FormState>();

    AwesomeDialog(
      width: 500,
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.bottomSlide,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit $title',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: title,
                  border: const OutlineInputBorder(),
                  errorMaxLines: 2,
                ),
                maxLines: maxLines,
                validator: (value) => Validator.validateField(value, title),
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        if (formKey.currentState!.validate()) {
          onSave(textController.text.trim());
        }
        textController.clear();
      },
    ).show();
  }

  Future<void> _showEditServicesDialog({
    required BuildContext context,
    required List<String> currentServices,
    required Function(List<String>) onSave,
  }) async {
    final services = List<String>.from(currentServices);
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final textTheme = TextTheme.of(context);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.bottomSlide,
      body: StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Services',
                  style: textTheme.headlineLarge,
                ),
                Gap(20),
                Form(
                  key: formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: textController,
                          decoration: InputDecoration(
                            labelText: 'Add new service',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a service';
                            }
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              services.add(textController.text);
                              textController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                if (services.isNotEmpty)
                  Text('Your Services:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                if (services.isEmpty) Text('No services added yet'),
                ...services
                    .map((service) => ListTile(
                          title: Text(service),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    setState(() => services.remove(service)),
                              ),
                              ReorderableDragStartListener(
                                index: services.indexOf(service),
                                child: Icon(Icons.drag_handle),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ],
            ),
          );
        },
      ),
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        onSave(services);
      },
      width: MediaQuery.of(context).size.width * 0.9,
    ).show();
  }

  // UPDATE WORK HOUR
  Future<void> _showAllWorkHoursDialog(BuildContext context) async {
    final initialTimes = await caretakerController.getWorkHours();
    final defaultTimes = caretakerController.getDefaultWorkHours();
    final workHours = Map<String, String>.from(
        initialTimes.isNotEmpty ? initialTimes : defaultTimes);
    final days = Days.values;
    final textTheme = TextTheme.of(context);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.bottomSlide,
      title: 'Set Work Hours',
      body: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              children: days.map((day) {
                final dayKey = day.toString().split('.').last.toLowerCase();
                final currentHours = workHours[dayKey]?.split('-') ?? ['', ''];

                return Column(
                  children: [
                    Text(
                      'Update Work Hours',
                      style: textTheme.bodyLarge,
                    ),
                    ListTile(
                      title: Text(day.toString().split('.').last),
                      subtitle: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  child: Text(currentHours[0].trim().isEmpty
                                      ? 'Start Time'
                                      : currentHours[0].trim()),
                                  onPressed: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setState(() {
                                        final endTime = currentHours.length > 1
                                            ? currentHours[1].trim()
                                            : '';
                                        workHours[dayKey] =
                                            '${caretakerController.formatTimeOfDay(time)} - $endTime';
                                      });
                                    }
                                  },
                                ),
                              ),
                              const Text('to'),
                              Expanded(
                                child: TextButton(
                                  child: Text(currentHours.length > 1 &&
                                          currentHours[1].trim().isNotEmpty
                                      ? currentHours[1].trim()
                                      : 'End Time'),
                                  onPressed: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setState(() {
                                        final startTime =
                                            currentHours[0].trim();
                                        workHours[dayKey] =
                                            '$startTime - ${caretakerController.formatTimeOfDay(time)}';
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          SwitchListTile(
                            title: const Text('Closed'),
                            value: workHours[dayKey]?.toLowerCase() == 'closed',
                            onChanged: (value) {
                              setState(() {
                                workHours[dayKey] =
                                    value ? 'Closed' : '9:00 AM - 5:00 PM';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        try {
          await caretakerController.updateAllWorkHours(workHours);
          setState(() {});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update work hours: $e')),
          );
        }
      },
    ).show();
  }

  //UPLOAD MEDIA DIALOG
  Future<void> _showMediaUploadDialog(BuildContext context) async {
    final result = await showDialog<MediaType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Media'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Upload Image'),
              onTap: () => Navigator.pop(context, MediaType.image),
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Upload Video'),
              onTap: () => Navigator.pop(context, MediaType.video),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final file = await ImagePicker().pickMedia(
          // mediaType:
          //     result == MediaType.image ? MediaType.image : MediaType.video,
          );

      if (file != null) {
        try {
          await caretakerController.uploadMedia(file, result);
          setState(() {});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteMedia(String mediaId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text('Are you sure you want to delete this media item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await caretakerController.deleteMedia(mediaId);
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  //DELETE STAFF
  Future<void> _deleteStaff(String id) async {
    try {
      await caretakerController.deleteStaff(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete staff: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showStaffDialog({StaffMember? staffMember}) {
    final isEditing = staffMember != null;
    final nameController = TextEditingController(
      text: isEditing ? staffMember!.name : '',
    );
    final emailController = TextEditingController(
      text: isEditing ? staffMember!.email : '',
    );
    DateTime selectedDate =
        isEditing ? staffMember!.dob.toDate() : DateTime.now();

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      title: isEditing ? 'Edit Staff Member' : 'Add Staff Member',
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      body: StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEditing) ...[
                    TextFormField(
                      initialValue: staffMember.id,
                      decoration: const InputDecoration(
                        labelText: 'ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      readOnly: true,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Enter full name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      hintText: 'Enter email address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'DOB: ${DateFormat('MM/dd/yyyy').format(selectedDate)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => selectedDate = date);
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      btnCancelText: 'Cancel',
      btnOkText: isEditing ? 'Update' : 'Add',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        if (nameController.text.isEmpty || emailController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill all fields'),
            ),
          );
          return;
        }

        // Basic email validation
        if (!emailController.text.contains('@')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid email'),
            ),
          );
          return;
        }

        try {
          final staff = StaffMember(
            id: isEditing ? staffMember!.id : '',
            caretakerId: '', // Will be set by controller
            name: nameController.text,
            dob: Timestamp.fromDate(selectedDate),
            email: emailController.text,
          );

          if (isEditing) {
            await caretakerController.updateStaff(
              staff,
              staffMember!.id,
            );
          } else {
            await caretakerController.addStaff(staff);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Staff ${isEditing ? 'updated' : 'added'} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      buttonsBorderRadius: BorderRadius.circular(8),
      buttonsTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      dialogBackgroundColor: Colors.white,
      dismissOnTouchOutside:
          false, // Prevent accidental dismissal during form filling
      width: 450, // Appropriate width for form fields
    ).show();
  }

  Widget _buildStaffTable(List<StaffMember> staffList) {
    final filteredStaff = _searchQuery.isEmpty
        ? staffList
        : staffList.where((staff) {
            return staff.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                staff.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                staff.email.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );
          }).toList();

    if (filteredStaff.isEmpty) {
      return const Center(
        child: Text(
          'No staff members found',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(), // ID
              1: IntrinsicColumnWidth(), // Name
              2: IntrinsicColumnWidth(), // Date of Birth
              3: IntrinsicColumnWidth(), // Email
              4: IntrinsicColumnWidth(), // Actions
            },
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: [
                  _buildTableHeader('ID'),
                  _buildTableHeader('Name'),
                  _buildTableHeader('Date of Birth'),
                  _buildTableHeader('Email'),
                  _buildTableHeader('Actions'),
                ],
              ),
              ...filteredStaff.map(
                (staff) => TableRow(
                  children: [
                    _buildTableCell(staff.id),
                    _buildTableCell(staff.name),
                    _buildTableCell(
                      DateFormat('MMM dd, yyyy').format(staff.dob.toDate()),
                    ),
                    _buildTableCell(staff.email),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showStaffDialog(staffMember: staff),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(staff.id),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(padding: const EdgeInsets.all(8.0), child: Text(text));
  }

  Future<void> _confirmDelete(String id) async {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Confirm Deletion',
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
      desc: 'Are you sure you want to delete this staff member?',
      descTextStyle: const TextStyle(
        fontSize: 16,
        height: 1.4,
      ),
      btnCancelText: 'Cancel',
      btnOkText: 'Delete',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await _deleteStaff(id);
      },
      btnOkColor: Colors.red,
      btnCancelColor: Colors.grey,
      buttonsBorderRadius: BorderRadius.circular(8),
      buttonsTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      dialogBackgroundColor: Colors.white,
      dismissOnTouchOutside: false, // Prevent accidental deletion
      headerAnimationLoop: false,
      showCloseIcon: false, // Force explicit choice
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DrawerLayout(
      title: 'Caretaker Profile',
      bottom: TabBar(
        controller: _tabController,
        tabs: const [Tab(text: 'Profile'), Tab(text: 'Staff List')],
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          // First Tab: Profile
          FutureBuilder<Caretaker?>(
            future: caretakerController.getCaretaker(),
            builder: (context, caretakerSnapshot) {
              if (caretakerSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(child: CustomLoader());
              }

              if (caretakerSnapshot.hasError || !caretakerSnapshot.hasData) {
                return Center(child: Text('Error: ${caretakerSnapshot.error}'));
              }

              final caretaker = caretakerSnapshot.data;

              debugPrint(
                'Location (Latitude): ${caretaker?.location.latitude}',
              );
              debugPrint(
                'Location (Longitude): ${caretaker?.location.longitude}',
              );
              debugPrint(
                'Created At: ${caretaker?.createdAt.toDate().toLocal().toString()}',
              );

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                  await caretakerController.getCaretaker();
                  return;
                },
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Profile Information',
                              style: textTheme.headlineLarge,
                            ),
                            TextButton.icon(
                              onPressed: () {
                                AwesomeDialog(
                                  context: context,
                                  dialogType: DialogType.info,
                                  animType: AnimType.bottomSlide,
                                  body: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Change Password',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: _passwordController,
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText: 'New Password',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  btnCancelOnPress: () {},
                                  btnCancelText: 'Cancel',
                                  btnOkOnPress: () {
                                    debugPrint(
                                        'Password changed to: ${_passwordController.text}');
                                  },
                                  btnOkText: 'Save',
                                  btnOkColor: Colors.blue,
                                  buttonsBorderRadius: BorderRadius.circular(8),
                                ).show();
                              },
                              label: const Text('Change Password'),
                              icon: const Icon(Icons.edit),
                            ),
                          ],
                        ),
                        LargeListTile(
                          leading: Icon(Icons.email),
                          title: Text(
                            'Email:',
                            style: textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            '${caretaker?.email ?? 'Not available'}',
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        LargeListTile(
                          leading: Icon(Icons.phone),
                          title: Text(
                            'Phone Number:',
                            style: textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            '${caretaker?.phone ?? 'Not available'}',
                            style: textTheme.bodyMedium,
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              _showEditDialog(
                                context: context,
                                title: 'Phone Number',
                                fieldName: 'phone',
                                currentValue: caretaker?.phone ?? '',
                                maxLines: 1,
                                onSave: (newPhone) {
                                  // Update your caretaker phone number here
                                  // Example:
                                  caretakerController.updatePhoneNumber(
                                      context, newPhone);
                                },
                              );
                            },
                            icon: Icon(Icons.edit),
                          ),
                        ),
                        LargeListTile(
                          leading: Icon(Icons.house),
                          title: Text(
                            'Autism Centre Type:',
                            style: textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            '${caretaker?.specialization ?? 'Not available'}',
                            style: textTheme.bodyMedium,
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              _showEditDialog(
                                context: context,
                                title: 'Autism Centre Type',
                                fieldName: 'specialization',
                                currentValue: caretaker?.phone ?? '',
                                maxLines: 1,
                                onSave: (newSpecialization) {
                                  // Update your caretaker phone number here
                                  // Example:
                                  caretakerController.updateSpecialization(
                                      context, newSpecialization);
                                },
                              );
                            },
                            icon: Icon(Icons.edit),
                          ),
                        ),
                        LargeListTile(
                          alignLeadingOnTop: true,
                          leading: Icon(Icons.info),
                          title: Text(
                            'About:',
                            style: textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            '${caretaker?.description ?? 'Not available'}',
                            style: textTheme.bodyMedium,
                          ),
                          trailing: IconButton(
                              onPressed: () {
                                _showEditDialog(
                                  context: context,
                                  title: 'About',
                                  fieldName: 'description',
                                  currentValue: caretaker?.phone ?? '',
                                  maxLines: 15,
                                  onSave: (newDescription) {
                                    // Update your caretaker phone number here
                                    // Example:
                                    caretakerController.updateDescription(
                                        context, newDescription);
                                  },
                                );
                              },
                              icon: Icon(Icons.edit)),
                        ),
                        LargeListTile(
                          alignLeadingOnTop: true,
                          leading: Icon(Icons.recommend),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Service Offer:',
                                  style: textTheme.bodyLarge),
                              if (caretaker?.services?.isNotEmpty ?? false)
                                ...caretaker!.services!
                                    .map((service) => Text('• $service',
                                        style: textTheme.bodyMedium))
                                    .toList(),
                              if (caretaker?.services == null ||
                                  caretaker!.services!.isEmpty)
                                Text('Not available',
                                    style: textTheme.bodyMedium),
                            ],
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              _showEditServicesDialog(
                                context: context,
                                currentServices: caretaker?.services ?? [],
                                onSave: (newServices) {
                                  caretakerController.updateServices(
                                      context, newServices);
                                },
                              );
                            },
                            icon: Icon(Icons.edit),
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Work Hours',
                                  style: textTheme.headlineLarge,
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _showAllWorkHoursDialog(context),
                                  label: const Text('Update Hours'),
                                  icon: const Icon(Icons.edit),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<Map<String, String>>(
                              future: caretakerController.getWorkHours(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                final workHours = snapshot.data ??
                                    caretakerController.getDefaultWorkHours();

                                // Build a single string with all work hours
                                final hoursText = Days.values.map((day) {
                                  final dayName =
                                      day.toString().split('.').last;
                                  return '$dayName: ${workHours[dayName.toLowerCase()] ?? 'Closed'}';
                                }).join('\n');

                                return LargeListTile(
                                  alignLeadingOnTop: true,
                                  leading: Icon(Icons.access_time_filled),
                                  title: Text(
                                    'Working From',
                                    style: textTheme.bodyLarge,
                                  ),
                                  subtitle: Text(
                                    hoursText,
                                    style: textTheme.bodyMedium,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Gap(10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Geolocation:',
                                style: textTheme.headlineLarge),
                            TextButton.icon(
                              onPressed: () async {
                                final locationService = LocationService();
                                final currentLocation = caretaker?.location;

                                final selectedLocation =
                                    await showDialog<LatLng>(
                                  context: context,
                                  builder: (context) => MapDialogWidget(
                                    initialLocation: currentLocation,
                                    locationService: locationService,
                                  ),
                                );

                                if (selectedLocation != null) {
                                  // Get address details for the selected location
                                  final locationDetails = await locationService
                                      .getLocationDetails(selectedLocation);

                                  setState(() {});

                                  await caretakerController.updateLocation(
                                      context,
                                      selectedLocation,
                                      locationDetails);
                                }
                              },
                              label: const Text('Create / Update'),
                              icon: const Icon(Icons.edit_location_alt),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LargeListTile(
                              leading: Icon(Icons.place),
                              title: Text(
                                'Place Name:',
                                style: textTheme.bodyLarge,
                              ),
                              subtitle: Text(
                                '${caretaker?.name ?? 'N/A'}',
                                style: textTheme.bodyMedium,
                              ),
                            ),
                            LargeListTile(
                              leading: Icon(Icons.location_city),
                              title: Text(
                                'Place Address:',
                                style: textTheme.bodyLarge,
                              ),
                              subtitle: Text(
                                '${caretaker?.address ?? 'N/A'}',
                                style: textTheme.bodyMedium,
                              ),
                            ),
                            LargeListTile(
                              leading: Icon(Icons.my_location),
                              title: Text(
                                'Latitude: ',
                                style: textTheme.bodyLarge,
                              ),
                              subtitle: Text(
                                '${caretaker?.location.latitude.toStringAsFixed(6) ?? 'N/A'}',
                                style: textTheme.bodyMedium,
                              ),
                            ),
                            LargeListTile(
                              leading: Icon(Icons.my_location),
                              title: Text(
                                'Longitude: ',
                                style: textTheme.bodyLarge,
                              ),
                              subtitle: Text(
                                '${caretaker?.location.longitude.toStringAsFixed(6) ?? 'N/A'}',
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        Gap(10),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Images and Video',
                                  style: textTheme.headlineLarge,
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _showMediaUploadDialog(context),
                                  label: const Text('Add Media'),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder<List<MediaItem>>(
                              future: caretakerController.getMediaItems(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Text('No media items yet');
                                }

                                final mediaItems = snapshot.data!;
                                final images = mediaItems
                                    .where(
                                        (item) => item.type == MediaType.image)
                                    .toList();
                                final videos = mediaItems
                                    .where(
                                        (item) => item.type == MediaType.video)
                                    .toList();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .stretch, // Changed from center
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Videos Carousel (if any)
                                    if (videos.isNotEmpty) ...[
                                      SizedBox(
                                        height: 500,
                                        child: videos.length == 1
                                            ? Center(
                                                child: SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.8,
                                                  child: VideoPlayerWidget(
                                                      videoUrl: videos[0].url),
                                                ),
                                              )
                                            : PageView.builder(
                                                itemCount: videos.length,
                                                itemBuilder: (context, index) {
                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20),
                                                    child: Center(
                                                      child: VideoPlayerWidget(
                                                          videoUrl:
                                                              videos[index]
                                                                  .url),
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                      // Add page indicator for multiple videos
                                      if (videos.length > 1) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: videos
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            return Container(
                                              width: 8,
                                              height: 8,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.grey.shade400,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                    ],

                                    // Images Grid (if any)
                                    if (images.isNotEmpty) ...[
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          return GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              crossAxisSpacing: 8,
                                              mainAxisSpacing: 8,
                                              childAspectRatio: 1,
                                              mainAxisExtent: constraints
                                                          .maxWidth /
                                                      3 -
                                                  8, // Calculate exact width
                                            ),
                                            itemCount: images.length,
                                            itemBuilder: (context, index) {
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  images[index].url,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      const Icon(
                                                          Icons.broken_image),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],

                                    // Fallback if no media
                                    if (images.isEmpty && videos.isEmpty)
                                      const Center(
                                          child: Text('No media available')),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Second Tab: Staff List
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Staff Management',
                    style: textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search Staff',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () => _showStaffDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Staff'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<Caretaker?>(
                    future: caretakerController.getCaretaker(),
                    builder: (context, caretakerSnapshot) {
                      if (caretakerSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CustomLoader());
                      }

                      if (caretakerSnapshot.hasError ||
                          !caretakerSnapshot.hasData) {
                        return Center(
                          child: Text(
                            'Error: ${caretakerSnapshot.error ?? "Caretaker not found"}',
                          ),
                        );
                      }

                      final caretaker = caretakerSnapshot.data!;

                      return StreamBuilder<List<StaffMember>>(
                        stream: caretakerController.getStaff(caretaker.id),
                        builder: (context, staffSnapshot) {
                          if (staffSnapshot.hasError) {
                            return Text('Error: ${staffSnapshot.error}');
                          }

                          if (staffSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CustomLoader());
                          }

                          final staffList = staffSnapshot.data ?? [];
                          return _buildStaffTable(staffList);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
