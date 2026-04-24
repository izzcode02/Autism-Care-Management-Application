import 'package:autism_care_management_application/common/widgets/balancedgridmenu.dart';
import 'package:autism_care_management_application/common/widgets/imageslide.dart';
import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/common/widgets/yes_no_dialog.dart';
import 'package:autism_care_management_application/data/services/permission_handler.dart';
import 'package:autism_care_management_application/screen/authentication/controllers/authentication.dart';
import 'package:autism_care_management_application/screen/authentication/views/settings.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:autism_care_management_application/screen/parents/model/parents_model.dart';
import 'package:autism_care_management_application/screen/parents/model/provider/child_provider.dart';
import 'package:autism_care_management_application/screen/parents/model/user_model.dart';
import 'package:autism_care_management_application/screen/parents/views/p_activity_monitor.dart';
import 'package:autism_care_management_application/screen/parents/views/p_activity_post.dart';
import 'package:autism_care_management_application/screen/parents/views/p_attendance.dart';
import 'package:autism_care_management_application/screen/parents/views/p_maps.dart';
import 'package:autism_care_management_application/screen/parents/views/p_news.dart';
import 'package:autism_care_management_application/screen/parents/views/p_recommendation.dart';
import 'package:autism_care_management_application/screen/parents/views/p_nutrition_monitor.dart';
import 'package:autism_care_management_application/screen/parents/views/p_payment.dart';
import 'package:autism_care_management_application/utils/rounded_bottom_navigation.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'p_profile.dart';

class ParentsHome extends StatefulWidget {
  const ParentsHome({super.key});

  @override
  State<ParentsHome> createState() => _ParentsHomeState();
}

class _ParentsHomeState extends State<ParentsHome> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const RecommendationScreen(),
      NewsScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: RoundedBottomNavigation(
        initialIndex: currentIndex,
        onItemSelected: (index) => setState(() => currentIndex = index),
        items: [
          NavItem(icon: Icon(Icons.home), label: 'Home'),
          NavItem(icon: Icon(Icons.recommend), label: 'Recommendation'),
          NavItem(icon: Icon(Icons.newspaper), label: 'News'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool skeletonLoading = true;
  final auth = Authentication();
  final _firestore = FirestoreService();
  Parent? parent;
  final PermissionHandler permissionHandler = PermissionHandler();

  Future<void> _requestPermissionsSequentially() async {
    await permissionHandler.requestLocationPermission(context);
    await permissionHandler.requestStoragePermission(context);
  }

  @override
  void initState() {
    super.initState();
    _requestPermissionsSequentially().then((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => skeletonLoading = false);
      });
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => skeletonLoading = false);
        showDialogUpdateProfile();
      }
    });
  }

  void showDialogUpdateProfile() {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    // if child is Empty show dialog.
    if (childProvider.children.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        animType: AnimType.scale,
        title: 'Reminder',
        desc:
            "Before start activity, please select children. \nIf you don't have yet, please update parent's and children's information in profile page",
        btnCancelOnPress: () {},
        btnCancelText: 'Close',
        btnCancelColor: Colors.grey,
        btnOkOnPress: () {
          Navigator.pushNamed(context, '/parents/profile');
        },
        btnOkColor: Colors.green,
        btnOkText: 'Go to Profile',
      ).show();
    }
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pushNamed(context, _getRouteForScreen(screen));
  }

  String _getRouteForScreen(Widget screen) {
    // Map your screens to route strings
    if (screen is ParentsAutismCenter) return '/parents/findcenter';
    if (screen is ParentsAttendance) return '/parents/attendance';
    if (screen is ParentsNutrition) return '/parents/nutrition';
    if (screen is ParentsActivity) return '/parents/activity';
    if (screen is ParentsActivityPost) return '/parents/activity/post';
    if (screen is ParentsPayment) return '/parents/payment';
    return '/parents/home';
  }

  Future getParentInfo() async {
    try {
      await _firestore.getParent();
    } catch (e) {
      debugPrint("Couldn't get parents info ${e.toString()}");
    }
  }

  Widget _buildMenuCards(BuildContext context) {
    return BalancedGridView(
      columnCount: 3,
      children: [
        MenuCardSmallTile(
          imageLink: 'assets/icons/search.png',
          label: 'Find Centre',
          onTap: () async {
            _navigateToScreen(context, ParentsAutismCenter());
          },
        ),
        MenuCardSmallTile(
          imageLink: 'assets/icons/attendance.png',
          label: 'Attendance',
          onTap: () async {
            _navigateToScreen(context, ParentsAttendance());
          },
        ),
        MenuCardSmallTile(
          imageLink: 'assets/icons/nutrition.png',
          label: 'Nutrition Planner',
          onTap: () async {
            _navigateToScreen(context, ParentsNutrition());
          },
        ),
        MenuCardSmallTile(
          imageLink: 'assets/icons/activity.png',
          label: 'Activity Planner',
          onTap: () async {
            _navigateToScreen(context, ParentsActivity());
          },
        ),
        MenuCardSmallTile(
          imageLink: 'assets/icons/payment.png',
          label: 'Payment',
          onTap: () async {
            _navigateToScreen(context, ParentsPayment());
          },
        ),
      ],
    );
  }

  void _showChildSelectionDialog(BuildContext context) async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    final textTheme = TextTheme.of(context);

    // Load children if not already loaded
    if (childProvider.children.isEmpty) {
      await childProvider.loadChildren();
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Select Child', style: textTheme.headlineLarge),
          SizedBox(
            width: double.maxFinite,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: childProvider.children.length,
                itemBuilder: (context, index) {
                  final child = childProvider.children[index];
                  return LargeListTile(
                    leading: Icon(Icons.child_care),
                    title: Text(child.name),
                    subtitle: Text(
                        '${child.autismCentreName ?? "Please select the autism centre by click 'Find Centre'"}'),
                    onTap: () {
                      childProvider.selectChild(child);
                      Navigator.pop(context);
                    },
                    disableChevron: true,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      btnCancel: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final textTheme = Theme.of(context).textTheme;
    final childProvider = Provider.of<ChildProvider>(context, listen: true);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: StreamBuilder<Users>(
            stream: _firestore.getCurrentUser(context),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasError) {
                return Center(child: Text('Error: ${userSnapshot.error}'));
              }

              final Users? user = userSnapshot.data;

              return Column(
                children: [
                  AppBar(
                    centerTitle: false,
                    title: Text(
                      "AutiCare",
                      style: textTheme.headlineLarge!.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    elevation: 0,
                  ),
                  Stack(
                    children: [
                      Container(
                        color: const Color(0xFFB4F19D),
                        width: screenSize.width,
                        height: 125,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: LargeListTile(
                          backgroundColor: Colors.white70,
                          leading: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              child: Image(
                                image: AssetImage('assets/icons/photo.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text(
                            "Welcome Back!",
                            style: textTheme.labelLarge!.copyWith(fontSize: 20),
                          ),
                          subtitle: Text(
                            user?.name.split(' ').take(2).join(' ') ?? 'N/A',
                            style: textTheme.labelLarge,
                          ),
                          trailing: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Settings(),
                                  ),
                                ),
                                icon: const Icon(Icons.settings),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final continueLogout = await showYesNoDialog(
                                    context: context,
                                    title: 'Log Out',
                                    message: 'Do you want to log out?',
                                  );
                                  if (continueLogout == true && mounted) {
                                    final childProvider =
                                        Provider.of<ChildProvider>(context,
                                            listen: false);

                                    // Clear provider data
                                    childProvider.disposeProvider();
                                    auth.logout(context);
                                  }
                                },
                                icon: const Icon(Icons.logout),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ImageSlider(
                    height: screenSize.height * 0.25,
                    width: screenSize.width,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: LargeListTile(
                      backgroundColor: Colors.white.withOpacity(0.5),
                      border: Border.all(color: Colors.black12),
                      title: const Text('Selected Child:'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (childProvider.selectedChild != null)
                            Text(childProvider.selectedChild!.name)
                          else
                            const Text('No child selected'),
                        ],
                      ),
                      onTap: () => _showChildSelectionDialog(context),
                    ),
                  ),
                  _buildMenuCards(context),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
