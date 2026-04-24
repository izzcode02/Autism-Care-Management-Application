import 'package:autism_care_management_application/common/widgets/yes_no_dialog.dart';
import 'package:autism_care_management_application/screen/authentication/controllers/authentication.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';

class DrawerLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const DrawerLayout({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    String? currentRoute = ModalRoute.of(context)?.settings.name;
    final auth = Authentication();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(title),
        actions: [
          IconButton(
              icon: const Icon(Icons.inbox),
              onPressed: () {
                Navigator.pushNamed(context, '/caretaker/inbox');
              }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 120),
              child: TextButton.icon(
                onPressed: () async {
                  AwesomeDialog(
                    width: 500,
                    context: context,
                    dialogType: DialogType.question,
                    animType: AnimType.scale,
                    title: 'Log Out',
                    desc: 'Do you want to log out?',
                    btnCancelText: 'Cancel',
                    btnOkText: 'Log Out',
                    btnOkIcon: Icons.logout, // Add logout icon
                    btnCancelIcon: Icons.cancel, // Add cancel icon
                    btnCancelOnPress: () {},
                    btnOkOnPress: () {
                      auth.logout(context);
                    },
                    btnOkColor: Colors.red, // Optional: makes logout button red
                  ).show();
                },
                icon: const Icon(Icons.logout),
                label: Text('Log Out'),
              ),
            ),
          ),
        ],
        bottom: bottom,
      ),
      drawer: Drawer(
        child: ListView(
          shrinkWrap: true,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/auticarebanner.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Text(
                'Autism Care Menu',
                style: TextStyle(color: Colors.black, fontSize: 24),
              ),
            ),
            _buildDrawerItem(
              context,
              label: 'Home',
              route: '/caretaker/home',
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context,
              label: 'Profile',
              route: '/caretaker/profile',
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context,
              label: 'Activity',
              route: '/caretaker/activity',
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context,
              label: 'Attendance',
              route: '/caretaker/attendance',
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context,
              label: 'Nutrition',
              route: '/caretaker/nutrition',
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context,
              label: 'Payment',
              route: '/caretaker/payment',
              currentRoute: currentRoute,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () async {
                final continueLogout = await showYesNoDialog(
                  context: context,
                  title: 'Log Out',
                  message: 'Do you want log out',
                  // title: AppLocalizations.of(context)!.logoutPopupTitle,
                  // message: AppLocalizations.of(context)!.logoutPopupMessage,
                );
                if (continueLogout == true) {
                  // apiClient.logout();

                  //temporary
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
          ],
        ),
      ),
      body: child,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required String label,
    required String route,
    required String? currentRoute,
  }) {
    return ListTile(
      title: Text(label),
      selected: currentRoute == route,
      selectedTileColor: Colors.teal.withOpacity(0.2), // highlight color
      onTap: () {
        if (currentRoute != route) {
          Navigator.pushReplacementNamed(context, route);
        } else {
          Navigator.pop(context); // just close drawer if already selected
        }
      },
    );
  }
}
