import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;

class FcmService {
  final authFirebase = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<String> getAccessToken() async {
    // Your client ID and client secret obtained from Google Cloud Console via REST API
    final serviceAccountJson = {
      //Your serviceAccoucnt Json Data
      "type": "service_account",
      "project_id": "autism-care-management-app",
      "private_key_id": "e848aebc76f6ef8ecef1c6a86b54d654ffb1c428",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDBiy38XwgHCKCR\nzvmBtmE006eSTKylEVnQ2BUhpM8RBjNHMLEJU7ZVVbPoS8z1bVK+kdcAnL7bInik\neoC3JcR4HUaFBpnPJB/EWb6Z3FydtPZOPTJj+uJ2kMoLriMni9YibBck9IboNBGi\n87kJ4hvrZUMEz1mLOoo3jLkrMNxudizoZTJQXZSypTAPHQlPP7DDwHxxNWfqV80p\nbukWEtC8KF3vb1nmprQ10zMpV0LNp+innQIJv+Ro2rj5uEZFqW9Ldeuk+w1zPpCL\nKf18tljiAU31AKkzAh9j0id+/pYfxTZwQSVjVrkN9PDfwKSpNGskNxUTNcFQytxJ\n/vSKO3yZAgMBAAECggEAHZPnDbP6NpT3cQEH+W5FUbzs1XtZQQqzRqrXI+KbcHcZ\nnA4RaCL+cPEdgukeo/02kYAZMvNBaZzNghlklVi0u0SCE+9Lzy+umSO78KiQENvo\nblGE42midUswTXOp1K/WpEEPkmq6OT9H2LbVdvCyoplBkjkb7p6eI9oiLDsV3N12\n4Fnquo684D/sRhORHM5qHnJIV0Bcp4YPsDwrGKTk8x6216JqE1UoyqxYKPW+2D+e\nOsb40IkqHGb1upEepRJW1md8ciDKTwY63io/DGbIVNIAEu8FsNDyLfxbZlJ69Pu5\nK5vSOxgbcL2nWkzTZvzM2eBO7OncdHf3yJQwgnUhTwKBgQD+WmUoj8FtCbyAZZu8\nLVJCuvnOcSHP+3YxXgVyAXbOizozf0JjDVP06lWZ1IP4yvsAeJ5csZv2wHE2377q\nD7j+KOlN4T9DotHeHyIgcea4lfiSzpCvseXDgGJFY2PZGpRntCP6XX1W2zibrXTn\nqfKiPHjsb59V/sTgZGOokoEFIwKBgQDCy/1GiR6HABZ212cfZT1y0VAFY++ORjPr\nnLD2PEQ+nZIPVdRAZ8cr7kf9hTAhIHRHS+K0voXif8Gs5tGfBUkTKzS7EQ95ghgE\npwVqvsXyEydeLQrUOoj6Vsb+9f7TX669WGPsXR3OzuGzHoh6MybzVLprUgRe3TOd\nlzawVuypEwKBgQDAMK2fKICPU3wLyLsURWqS4ZVAWFukO+3i/5g9vL1489rWbqJL\nFhcKSMbFpb7Sjw16HaoLgGjI2kCxpf8r/RVbdq5TGpAjGzRZEk1HFsmvUCKzS0Io\nf9ONFcUriR45PcxFT+iflWTP7HWprDdZlSCxVeBJR06uPAOnSjPDfG/g4QKBgEgw\nToE4SW7gMnMCKn4xB4+oUA5fVaSVEaKsI8xs0yGdRUaXmRvxGZeHK3ihRg/QtibB\n0ZcH0Bf7HmwT8fULgWQwK89zaBewhXQb7V78qeCnBnzZFl1GAAM962sLAM+WcuxK\neGVcsLI2at/1XcBjenjMmnUxJNt/ACTTp/m7jOKvAoGATz1GFJ0h0nAVVsos/8GJ\nuZch7aSt7p3/1L3E3a5sSxCjs8nXkTUcAgRHP/OhCnSBnahLdL77DmFfQHRDlgVc\n7ZorWlG08HWbxFrVuAxLYNLWv+7uXR0SijvcQ3GhJ0fB0e5K8VUP/XrP1JSduXMb\nCae0I2FC/p6l/iDS2Yc692M=\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-fbsvc@autism-care-management-app.iam.gserviceaccount.com",
      "client_id": "116220378510185561832",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40autism-care-management-app.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    // Obtain the access token
    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client);

    // Close the HTTP client
    client.close();

    // Return the access token
    return credentials.accessToken.data;
  }

  Future<void> sendFCMMessage(
    String title,
    String body,
  ) async {
    final String serverKey = await getAccessToken(); // Your FCM server key
    final String fcmEndpoint =
        'https://fcm.googleapis.com/v1/projects/autism-care-management-app/messages:send';
    final currentFCMToken = await FirebaseMessaging.instance.getToken();
    print("fcmkey : $currentFCMToken");
    final Map<String, dynamic> message = {
      'message': {
        'token':
            currentFCMToken, // Token of the device you want to send the message to
        'notification': {'body': body, 'title': title},
        'data': {
          'current_user_fcm_token':
              currentFCMToken, // Include the current user's FCM token in data payload
        },
      }
    };

    final http.Response response = await http.post(
      Uri.parse(fcmEndpoint),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('FCM message sent successfully');
    } else {
      print('Failed to send FCM message: ${response.statusCode}');
    }
  }

  Future<void> saveTokenToFirestore() async {
    String? token = await getAccessToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(authFirebase.currentUser!.uid)
          .update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  initNotify() async {
    // Initialize notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      // Add iOS settings if needed
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('Notification permission granted: ${settings.authorizationStatus}');
  }

  void showFlutterNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'your_channel_id',
            'your_channel_name',
            channelDescription: 'your_channel_description',
            importance: Importance.max,
            priority: Priority.high,
            icon: android.smallIcon,
          ),
        ),
      );
    }
  }
}
