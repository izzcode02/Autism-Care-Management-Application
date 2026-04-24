// verify_email.dart
import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/screen/authentication/controllers/authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String roles;

  const VerifyEmailScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.roles,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isEmailVerified = false;
  bool _isLoading = false;
  bool _isResending = false;
  late User _user;
  final Authentication _auth = Authentication();

  @override
  void initState() {
    super.initState();
    _initVerification();
  }

  Future<void> _initVerification() async {
    setState(() => _isLoading = true);

    try {
      print('Creating user with email: ${widget.email}');
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      _user = userCredential.user!;
      print('User created: ${_user.uid}');

      await _auth.sendEmailVerification(_user);
      print('Verification email sent to ${_user.email}');

      _checkEmailVerification();
    } catch (e) {
      print('Initialization error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _checkEmailVerification() async {
    setState(() => _isLoading = false);

    print('Starting verification checks for ${_user.email}');

    int attempts = 0;
    const maxAttempts = 20; // 1 minute timeout

    await Future.doWhile(() async {
      attempts++;
      await Future.delayed(const Duration(seconds: 3));

      print('Verification check #$attempts');
      await _user.reload();
      final currentUser = FirebaseAuth.instance.currentUser;
      final isVerified = currentUser?.emailVerified ?? false;
      print('Current verification status: $isVerified');

      if (isVerified) {
        print('Email verified! Completing registration...');
        if (mounted) {
          setState(() => _isEmailVerified = true);
          await _completeRegistration();
        }
        return false;
      }

      if (attempts >= maxAttempts) {
        print('Maximum verification attempts reached');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Verification timeout. Please try again.')),
          );
        }
        return false;
      }

      return true;
    });
  }

  Future<void> _completeRegistration() async {
    try {
      // Complete the registration process
      await _auth.register(
        context,
        widget.name,
        widget.email,
        widget.password,
        widget.roles,
        user: _user, // Pass the already created user
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);
    try {
      await _auth.sendEmailVerification(_user);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email resent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resending email: ${e.toString()}')),
      );
    } finally {
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        leading: null,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CustomLoader())
          : _isEmailVerified
              ? _emailSuccess(context)
              : _askVerify(context),
    );
  }

  Widget _askVerify(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/email.json',
            repeat: true,
            animate: true,
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 20),
          Text(
            'A verification email has been sent to ${widget.email}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          const Text(
            'Please check your inbox and verify your email address to continue.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isResending ? null : _resendVerificationEmail,
            child: _isResending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(),
                  )
                : const Text('Resend Verification Email'),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Registration'),
          ),
        ],
      ),
    );
  }

  Widget _emailSuccess(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/congrats.json',
            repeat: true,
            animate: true,
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 20),
          Text(
            'Email Verified Successfully!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          const Text(
            'Your account has been successfully created. You can now log in.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Go to Login Page'),
          ),
        ],
      ),
    );
  }
}
