import 'package:autism_care_management_application/data/services/permission_handler.dart';
import 'package:autism_care_management_application/screen/caretaker/controllers/caretaker_controller.dart';
import 'package:autism_care_management_application/utils/drawer_layout.dart';
import 'package:flutter/material.dart';
import 'package:autism_care_management_application/common/widgets/largelisttile.dart';

class CaretakerHome extends StatefulWidget {
  const CaretakerHome({super.key});

  @override
  State<CaretakerHome> createState() => _CaretakerHomeState();
}

class _CaretakerHomeState extends State<CaretakerHome> {
  final PermissionHandler permissionHandler = PermissionHandler();
  final caretakercontroller = CaretakerController();
  String _caretakerName = 'Company Name';

  Future<void> _requestPermissionsSequentially() async {
    await permissionHandler.requestLocationPermission(context);
    await permissionHandler.requestStoragePermission(context);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _requestPermissionsSequentially();
    _loadCaretakerName();
  }

  Future<void> _loadCaretakerName() async {
    try {
      final caretaker = await caretakercontroller.getCaretaker();
      if (caretaker != null) {
        setState(() {
          _caretakerName = caretaker.name;
        });
      }
    } catch (e) {
      debugPrint('Error loading caretaker name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    // final screenSize = MediaQuery.sizeOf(context);

    return DrawerLayout(
      backgroundColor: Colors.black87,
      title: 'Caretaker Dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _caretakerName.isNotEmpty
                  ? 'Welcome to Dashboard $_caretakerName'
                  : 'Welcome to Dashboard',
              style: textTheme.headlineLarge!.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Autism Care Management Application',
              style: textTheme.headlineLarge!.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Please choose the management section to edit.',
              style: textTheme.headlineMedium!.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 24),
            _buildTileRow([
              LargeListTile(
                backgroundColor: Colors.white,
                alignLeadingOnTop: true,
                disableChevron: true,
                title: Image.asset(
                  'assets/images/profile1.png',
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.fitWidth,
                ),
                subtitle: Text('Profile Edit', style: textTheme.bodyLarge),
                bottom: Text(
                  'Update Profile, Geolocation and Staff List',
                  style: textTheme.bodyMedium,
                ),
                onTap: () => _navigateTo(context, "/caretaker/profile"),
              ),
              LargeListTile(
                backgroundColor: Colors.white,
                alignLeadingOnTop: true,
                disableChevron: true,
                title: Image.asset(
                  'assets/images/approvalrequest1.png',
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.fitWidth,
                ),
                subtitle: Text('Approval List', style: textTheme.bodyLarge),
                bottom: Text(
                  'View and accept the request list here',
                  style: textTheme.bodyMedium,
                ),
                onTap: () => _navigateTo(context, "/caretaker/approval"),
              ),
            ]),
            const SizedBox(height: 16),
            _buildTileRow([
              LargeListTile(
                backgroundColor: Colors.white,
                alignLeadingOnTop: true,
                disableChevron: true,
                title: Image.asset(
                  'assets/images/attendance1.png',
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.fitWidth,
                ),
                subtitle: Text('Attendance List', style: textTheme.bodyLarge),
                bottom: Text(
                  'View attendance list and absence letter',
                  style: textTheme.bodyMedium,
                ),
                onTap: () => _navigateTo(context, "/caretaker/attendance"),
              ),
              LargeListTile(
                backgroundColor: Colors.white,
                alignLeadingOnTop: true,
                disableChevron: true,
                title: Image.asset(
                  'assets/images/nutrition1.png',
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.fitWidth,
                ),
                subtitle: Text('Nutrition Planner', style: textTheme.bodyLarge),
                bottom: Text(
                  'Add, edit and delete nutrition plans',
                  style: textTheme.bodyMedium,
                ),
                onTap: () => _navigateTo(context, "/caretaker/nutrition"),
              ),
            ]),
            const SizedBox(height: 16),
            _buildTileRow([
              LargeListTile(
                backgroundColor: Colors.white,
                alignLeadingOnTop: true,
                disableChevron: true,
                title: Image.asset(
                  'assets/images/activityplanner1.png',
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.fitWidth,
                ),
                subtitle: Text('Activity Planner', style: textTheme.bodyLarge),
                bottom: Text(
                  'Add, edit and remove schedules and broadcasts',
                  style: textTheme.bodyMedium,
                ),
                onTap: () => _navigateTo(context, '/caretaker/activity'),
              ),
              LargeListTile(
                backgroundColor: Colors.white,
                alignLeadingOnTop: true,
                disableChevron: true,
                title: Image.asset(
                  'assets/images/payment1.png',
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.fitWidth,
                ),
                subtitle: Text('Payment List', style: textTheme.bodyLarge),
                bottom: Text(
                  'See the payment list here.',
                  style: textTheme.bodyMedium,
                ),
                onTap: () => _navigateTo(context, '/caretaker/payment'),
              ),
            ]),
            _buildTileRow([
              LargeListTile(
                backgroundColor: Colors.white,
                alignLeadingOnTop: true,
                disableChevron: true,
                title: Image.asset(
                  'assets/images/childparent1.png',
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.fitWidth,
                ),
                subtitle: Text(
                  'Child and Parent Information',
                  style: textTheme.bodyLarge,
                ),
                bottom: Text(
                  'See the information for child and parent',
                  style: textTheme.bodyMedium,
                ),
                onTap: () => _navigateTo(context, '/caretaker/childparentinfo'),
              ),
              LargeListTile(
                backgroundColor: Colors.white,
                alignLeadingOnTop: true,
                disableChevron: true,
                title: Image.asset(
                  'assets/images/feedback1.png',
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.fitWidth,
                ),
                subtitle: Text(
                  'Feedback and Rating',
                  style: textTheme.bodyLarge,
                ),
                bottom: Text(
                  'See the feedback and rating centre.',
                  style: textTheme.bodyMedium,
                ),
                onTap: () => _navigateTo(context, '/caretaker/feedbackreview'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pop(context); // Close drawer before navigating
    Navigator.pushNamed(context, routeName);
  }

  Widget _buildTileRow(List<Widget> tiles) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tiles
          .map(
            (tile) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: tile,
              ),
            ),
          )
          .toList(),
    );
  }
}
