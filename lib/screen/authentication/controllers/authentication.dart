import 'package:autism_care_management_application/screen/authentication/model/caretaker_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/User.dart';

class Authentication {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ======================== ID GENERATION ========================
  Future<String> _getNextId(String collectionPath, String prefix) async {
    try {
      final counterRef = _firestore.collection('counters').doc(collectionPath);

      // First try to get the current count without transaction
      final currentDoc = await counterRef.get();
      int currentCount = 1;

      if (currentDoc.exists) {
        currentCount = (currentDoc.data()?['count'] ?? 0) + 1;
      }

      // Then attempt to update with transaction
      try {
        await _firestore.runTransaction((transaction) async {
          final doc = await transaction.get(counterRef);
          if (doc.exists) {
            currentCount = (doc.data()?['count'] ?? 0) + 1;
          }
          transaction.set(counterRef, {'count': currentCount});
        });
      } catch (e) {
        // If transaction fails, use the count we got before
        print('Transaction failed, using fallback count: $e');
      }

      return '$prefix${currentCount.toString().padLeft(3, '0')}';
    } catch (e) {
      print('Error in _getNextId: $e');
      throw Exception('Failed to generate ID. Please try again.');
    }
  }

  // ======================== LOGIN VIA EMAIL AND PASSWORD ========================
  Future<Users?> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          // Convert Firestore document to UserModel (JSON data)
          Users userModel = Users.fromJson(
            userDoc.data() as Map<String, dynamic>,
          );

          //Save shared prefs here
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString("userID", user.uid);

          //Navigator Route to Home Screen
          // Role-based navigation
          if (userModel.isParent) {
            var roles = "Parent";
            prefs.setString("roles", roles);
            Navigator.pushReplacementNamed(context, '/parents/home');
          } else if (userModel.isCaretaker) {
            var roles = "Caretaker";
            prefs.setString("roles", roles);
            Navigator.pushReplacementNamed(context, '/caretaker/home');
          } else {
            // Handle other roles or no role assigned
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid credentials')),
            );

            return null;
          }

          return userModel;
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not found')));
          return null;
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Authentication failed')));
        return null;
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        errorMessage = 'Invalid credential, please try again';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many attempts. Try again later';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred')),
      );
      return null;
    }
  }

  // ======================== LOGIN VIA GOOGLE AUTH ========================
  Future<Users?> loginWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User canceled login

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user == null) return null;

      //Save shared prefs here
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("userID", user.uid);

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      Users userModel = Users(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        roles: 'Parent',
      );

      if (!userDoc.exists) {
        // Save new user data to Firestore
        await _firestore
            .collection("users")
            .doc(user.uid)
            .set(userModel.toJson());
      }

      //Save share prefs for roles
      var roles = "Parent";
      prefs.setString("roles", roles);

      //Navigator Route to Home Screen
      Navigator.pushReplacementNamed(context, '/parents/home');

      return userModel;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Login Error: ${e.toString()}')),
      );
      return null;
    }
  }

  // ======================== LOGOUT AUTH ========================
  Future<void> logout(BuildContext context) async {
    try {
      await _auth.signOut();

      //Clear prefs from storage local
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.clear();

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (Route<dynamic> route) => false, // Removes all previous routes
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Log Out Error: ${e.toString()}')));
    }
  }

  // ======================== REGISTRATION ========================
// Update in authentication.dart

  Future<Users?> register(
    BuildContext context,
    String name,
    String email,
    String password,
    String roles, {
    User? user, // Optional parameter for pre-created user
  }) async {
    try {
      UserCredential userCredential;

      if (user == null) {
        // Create user in Firebase Authentication if not provided
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = userCredential.user;
      }

      if (user != null) {
        // Create user data in Firestore
        Users newUser = Users(
          uid: user.uid,
          email: email,
          name: name,
          roles: roles,
        );
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toJson());

        if (roles == "Caretaker") {
          final caretakerId = await _getNextId('caretaker', 'C');

          // Create a new Caretaker with default values
          final newCaretaker = Caretaker(
            id: caretakerId,
            authId: user.uid,
            name: name,
            email: email,
            address: '',
            phone: '',
            location: LatLng(0, 0),
            createdAt: Timestamp.now(),
          );

          await _firestore
              .collection('caretaker')
              .doc(caretakerId)
              .set(newCaretaker.toJson());
        }

        return newUser;
      } else {
        debugPrint('Registration failed.');
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      return null;
    }
  }

// ======================== VERIFY EMAIL ========================

  Future<void> sendEmailVerification(User user) async {
    try {
      print('Sending verification email to ${user.email}');
      await user.sendEmailVerification();
      print('Verification email sent successfully');
    } catch (e) {
      print('Error sending verification email: $e');
      rethrow;
    }
  }

  Future<bool> checkEmailVerified(User user) async {
    // Reload user to get latest email verification status
    await user.reload();
    return user.emailVerified;
  }

  // =================== DELETE USER ============================

  Future<void> deleteUserAccount(BuildContext context) async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Important: Re-authenticate the user first
        // This example assumes you have the user's current credentials
        // You'll need to get these from your login form or stored securely
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: 'currentPassword', // Get this from your user input
        );

        // Re-authenticate
        await user.reauthenticateWithCredential(credential);

        // Delete the user
        await user.delete();

        //Clear prefs from storage local
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.clear();

        print('User account deleted successfully');
        // You may want to navigate to a different screen or show a success message
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (Route<dynamic> route) => false, // Removes all previous routes
        );
      } else {
        print('No user is currently signed in');
      }
    } on FirebaseAuthException catch (e) {
      print('Error deleting user: ${e.message}');
      // Handle specific error cases
      if (e.code == 'requires-recent-login') {
        print(
            'The user must reauthenticate before this operation can be executed');
      }
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  // =================== CHANGE PASSWORD ============================
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Reauthenticate the user first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);

      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to change password';

      if (e.code == 'wrong-password') {
        errorMessage = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        errorMessage = 'New password is too weak (min 6 characters)';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'Session expired. Please log in again';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred')),
      );
      return false;
    }
  }

  void clearPasswordFields() {
    oldPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
  }

}
