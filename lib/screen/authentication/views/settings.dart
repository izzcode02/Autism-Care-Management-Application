import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/screen/authentication/controllers/authentication.dart';
import 'package:autism_care_management_application/screen/parents/model/provider/child_provider.dart';
import 'package:autism_care_management_application/utils/validator.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final controller = Authentication();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();

  void _showChangePasswordDialog() {
    final textTheme = Theme.of(context).textTheme;
    final authController =
        Authentication(); // Create instance of your controller

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.bottomSlide,
      desc: 'Enter your current password and new password',
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Change Password',
                style: textTheme.headlineLarge,
              ),
              const Gap(15),
              TextFormField(
                controller: authController.oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: authController.newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: Validator.validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: authController.confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value != authController.newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      btnOkOnPress: () async {
        if (_formKey.currentState!.validate()) {
          final success = await authController.changePassword(
            currentPassword: authController.oldPasswordController.text,
            newPassword: authController.newPasswordController.text,
            context: context,
          );

          if (success) {
            _showSuccessDialog('Password changed successfully!');
            authController.clearPasswordFields();
            _clearPasswordFields();
          }
        }
      },
      btnCancelOnPress: () {
        authController.clearPasswordFields();
      },
    ).show();
  }

  void showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.bottomSlide,
      title: 'Error',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  void _showSuccessDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.bottomSlide,
      title: 'Success',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  void _showPrivacyPolicyDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: 'Privacy Policy',
      desc:
          'Your privacy is important to us. We collect and use your information to provide better care management services.',
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            '1. Information Collection\n'
            'We collect information you provide directly to us, such as when you create an account, update your profile, or contact us.\n\n'
            '2. Information Use\n'
            'We use the information we collect to provide, maintain, and improve our services.\n\n'
            '3. Information Sharing\n'
            'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent.\n\n'
            '4. Data Security\n'
            'We implement appropriate security measures to protect your personal information.\n\n'
            '5. Contact Us\n'
            'If you have any questions about this Privacy Policy, please contact us.',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ),
      btnOkOnPress: () {},
    ).show();
  }

  void _showAboutDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.leftSlide,
      title: 'About',
      desc: 'Autism Care Management Application',
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.favorite,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Autism Care Management Application',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              'This application is designed to help manage and support individuals with autism spectrum disorders. Our goal is to provide comprehensive care management tools for families and caregivers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Made with ❤️ for the autism community',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      btnOkOnPress: () {},
    ).show();
  }

  void _showDeleteAccountDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.topSlide,
      title: 'Delete Account',
      desc:
          'Are you sure you want to delete your account? This action cannot be undone.',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        _showFinalDeleteConfirmation();
      },
      btnOkColor: Colors.red,
      btnOkText: 'Delete',
      btnCancelColor: Colors.grey,
      btnCancelText: 'Cancel',
    ).show();
  }

  void _showFinalDeleteConfirmation() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Final Confirmation',
      desc: 'Type "DELETE" to confirm account deletion',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'This will permanently delete your account and all associated data. This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Type "DELETE" to confirm',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // You can store this value in a variable if needed
              },
            ),
          ],
        ),
      ),
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        // TODO: Implement account deletion logic
        controller.deleteUserAccount(context);
        _showSuccessDialog(
            'Account deletion requested. You will receive a confirmation email.');
      },
      btnOkColor: Colors.red,
      btnOkText: 'Delete Forever',
      btnCancelText: 'Cancel',
    ).show();
  }

  void _showLogoutDialog() {
    final auth = Authentication();

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: 'Log Out',
      desc: 'Are you sure you want to log out?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        if (mounted) {
          final childProvider =
              Provider.of<ChildProvider>(context, listen: false);

          // Clear provider data
          childProvider.disposeProvider();
          await auth.logout(context);
        }
      },
      btnOkText: 'Log Out',
      btnCancelText: 'Cancel',
    ).show();
  }

  void _clearPasswordFields() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  color: Colors.green,
                  width: screenSize.width,
                  height: screenSize.height * 0.2,
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  direction: Axis.vertical,
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: screenSize.width * 0.15,
                    ),
                    Text(
                      'Settings',
                      style: textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  LargeListTile(
                    title: const Text('Change Password'),
                    leading: const Icon(Icons.lock_outline),
                    onTap: _showChangePasswordDialog,
                  ),
                  const SizedBox(height: 2),
                  LargeListTile(
                    title: const Text('Privacy Policy'),
                    leading: const Icon(Icons.privacy_tip_outlined),
                    onTap: _showPrivacyPolicyDialog,
                  ),
                  const SizedBox(height: 2),
                  LargeListTile(
                    title: const Text('About'),
                    leading: const Icon(Icons.info_outline),
                    onTap: _showAboutDialog,
                  ),
                  const SizedBox(height: 2),
                  LargeListTile(
                    title: const Text('Delete Account'),
                    leading:
                        const Icon(Icons.delete_outline, color: Colors.red),
                    backgroundColor: Colors.red[50],
                    onTap: _showDeleteAccountDialog,
                  ),
                  const Divider(height: 32),
                  LargeListTile(
                    title: const Text('Log Out'),
                    leading: const Icon(Icons.logout, color: Colors.orange),
                    backgroundColor: Colors.orange[50],
                    onTap: _showLogoutDialog,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
