import 'dart:convert';

import 'package:autism_care_management_application/data/services/fcm_service.dart';
import 'package:autism_care_management_application/screen/authentication/views/login.dart';
import 'package:autism_care_management_application/screen/authentication/views/register.dart';
import 'package:autism_care_management_application/screen/caretaker/controllers/caretaker_controller.dart';
import 'package:autism_care_management_application/screen/caretaker/views/c_activity_planner.dart';
import 'package:autism_care_management_application/screen/caretaker/views/c_approval_list.dart';
import 'package:autism_care_management_application/screen/caretaker/views/c_attendance.dart';
import 'package:autism_care_management_application/screen/caretaker/views/c_child_parents.dart';
import 'package:autism_care_management_application/screen/caretaker/views/c_home.dart';
import 'package:autism_care_management_application/screen/caretaker/views/c_inbox.dart';
import 'package:autism_care_management_application/screen/caretaker/views/c_nutrition_planner.dart';
import 'package:autism_care_management_application/screen/caretaker/views/c_payment.dart';
import 'package:autism_care_management_application/screen/caretaker/views/c_profile.dart';
import 'package:autism_care_management_application/screen/caretaker/views/c_review_feedback.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:autism_care_management_application/screen/parents/model/provider/child_provider.dart';
import 'package:autism_care_management_application/screen/parents/views/p_activity_monitor.dart';
import 'package:autism_care_management_application/screen/parents/views/p_activity_post.dart';
import 'package:autism_care_management_application/screen/parents/views/p_attendance.dart';
import 'package:autism_care_management_application/screen/parents/views/p_maps.dart';
import 'package:autism_care_management_application/screen/parents/views/p_maps_inbox.dart';
import 'package:autism_care_management_application/screen/parents/views/p_nutrition_monitor.dart';
import 'package:autism_care_management_application/screen/parents/views/p_payment.dart';
import 'package:autism_care_management_application/screen/parents/views/p_register_children.dart';
import 'package:autism_care_management_application/screen/parents/views/p_register_parents.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screen/parents/views/p_home.dart';
import 'screen/parents/views/p_profile.dart';
import 'splash_screen.dart';

final fcmService = FcmService();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  fcmService.showFlutterNotification(message);

  print("Handling a background message: ${message.messageId}");
}

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final double screenWidth = WidgetsBinding
          .instance.platformDispatcher.views.first.physicalSize.width /
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
  if (screenWidth < 600) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_BASE_URL'] as String,
    anonKey: dotenv.env['SUPABASE_KEY'] as String,
  );

  fcmService.requestNotificationPermission();
  fcmService.initNotify();

  await FirebaseMessaging.instance.setAutoInitEnabled(true);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.notification?.title}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      fcmService.showFlutterNotification(message);
    }
  });

  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('Message data: $fcmToken');

  runApp(
    MultiProvider(
      providers: [
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider(
          create: (context) => ChildProvider(context.read<FirestoreService>()),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autism Care Management Application',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        //Skeletonizer Globally
        extensions: [
          SkeletonizerConfigData(
            effect: const ShimmerEffect(),
            justifyMultiLineText: true,
            ignoreContainers: false,
          ),
        ],

        // Primary Theme Color
        primarySwatch: Colors.lightGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFB4F19D),
          brightness:
              Brightness.light, // Change to Brightness.dark for dark mode
        ),

        // Typography
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: getResponsiveFontSize(32),
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          displayMedium: TextStyle(
            fontSize: getResponsiveFontSize(28),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          displaySmall: TextStyle(
            fontSize: getResponsiveFontSize(24),
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
          headlineMedium: TextStyle(
            fontSize: getResponsiveFontSize(20),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          bodyLarge: TextStyle(
            fontSize: getResponsiveFontSize(18),
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: getResponsiveFontSize(16),
            color: Colors.black54,
          ),
          labelLarge: TextStyle(
            fontSize: getResponsiveFontSize(14),
            fontWeight: FontWeight.w500,
            color: Colors.deepPurple,
          ),
        ),

        // AppBar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFB4F19D),
          foregroundColor: Colors.black,
          elevation: 4,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        // Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 156, 242, 125),
            foregroundColor: Colors.white,
            minimumSize: Size.fromHeight(40),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // TextButton Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color.fromARGB(255, 156, 242, 125),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Outlined Button Theme
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Color.fromARGB(255, 156, 242, 125),
            side: const BorderSide(color: Colors.lightGreen),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Input Decoration Theme (Text Fields)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[200],
          isDense: true,
          contentPadding: EdgeInsets.all(5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            // borderSide: const BorderSide(color: Colors.lightGreen),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            // borderSide: const BorderSide(color: Colors.lightGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(width: 2),
          ),
          // labelStyle: const TextStyle(color: Colors.lightGreen),
        ),

        // Floating Action Button (FAB) Theme
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color.fromARGB(255, 156, 242, 125),
          foregroundColor: Colors.white,
          elevation: 4,
        ),

        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color.fromARGB(255, 156, 242, 125),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),

        // Card Theme
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          shadowColor: Colors.black26,
        ),

        // Chip Theme
        chipTheme: ChipThemeData(
          backgroundColor: Color.fromARGB(255, 156, 242, 125),
          labelStyle: TextStyle(color: Colors.white),
        ),
      ),
      //debug temporary

      // Initial Route
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        //caretaker
        '/caretaker/home': (context) => const CaretakerHome(),
        '/caretaker/inbox': (context) => const CaretakerInbox(),
        '/caretaker/profile': (context) => const CaretakerProfile(),
        '/caretaker/approval': (context) => const CaretakerApproval(),
        '/caretaker/activity': (context) => const CaretakerActivity(),
        '/caretaker/attendance': (context) => const CaretakerAttendance(),
        '/caretaker/nutrition': (context) => const CaretakerNutrition(),
        '/caretaker/payment': (context) => const CaretakerPayment(),
        '/caretaker/childparentinfo': (context) =>
            const CaretakerChildParents(),
        '/caretaker/feedbackreview': (context) => CaretakerFeedbackReview(),

        //parents
        '/parents/home': (context) => const ParentsHome(),
        '/parents/profile': (context) => const ProfileScreen(),
        '/parents/profile/register-parents': (context) =>
            const ParentsRegistration(),
        '/parents/profile/register-children': (context) =>
            const ChildrenRegistration(),
        '/parents/findcenter': (context) => ParentsAutismCenter(),
        '/parents/findcenter/inbox': (context) => ParentsMapsInbox(),
        '/parents/attendance': (context) => ParentsAttendance(),
        '/parents/nutrition': (context) => ParentsNutrition(),
        '/parents/activity': (context) => ParentsActivity(),
        '/parents/activity/post': (context) => ParentsActivityPost(),
        '/parents/payment': (context) => ParentsPayment(),
      },
    );
  }

  // 🔹 Function to scale text size based on screen width
  double getResponsiveFontSize(double baseSize) {
    return (baseSize *
            0.0028 *
            WidgetsBinding
                .instance.platformDispatcher.views.first.physicalSize.width)
        .clamp(12.0, baseSize);
  }
}
