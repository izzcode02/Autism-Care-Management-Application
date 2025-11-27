import 'package:autism_care_management_application/screen/caretaker/controllers/caretaker_controller.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _destinationRoute;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userID");
    final rolesToken = prefs.getString("roles");

    if (!mounted) return;

    String destinationRoute;
    if (token != null && rolesToken != null) {
      if (rolesToken == 'Parent') {
        destinationRoute = '/parents/home';

        // temporary
        // final parentController = FirestoreService();
        // parentController.startListeningForNewNotifications();
      } else {
        destinationRoute = '/caretaker/home';

        //temporary
        // final caretakerController = CaretakerController();
        // caretakerController.startListeningForNewNotifications();
      }
      print(
          'Token = $token, User logged in ($rolesToken), will redirect after splash');
    } else {
      destinationRoute = '/login';
      print('No user logged in, will show login after splash');
    }

    if (mounted) {
      setState(() {
        _destinationRoute = destinationRoute;
      });
    }
  }

  Widget _getScreenAfterSplash() {
    return Builder(
      builder: (context) {
        // This ensures the splash animation completes before navigation
        Future.delayed(Duration.zero, () {
          Navigator.pushReplacementNamed(context, _destinationRoute!);
        });
        return Container(color: Colors.green[50]); // Blank transition screen
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      duration: 2000, // Full 2 seconds splash duration
      splash: Container(
        width: 100,
        child: Image.asset("assets/icons/logo.png"),
      ),
      nextScreen: _getScreenAfterSplash(),
      splashTransition: SplashTransition.fadeTransition,
      backgroundColor: Colors.green[50]!,
      splashIconSize: 150,
      animationDuration: const Duration(milliseconds: 800),
    );
  }
}
