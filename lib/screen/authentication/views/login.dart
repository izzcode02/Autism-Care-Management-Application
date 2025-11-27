import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/utils/google_logo.dart';
import 'package:autism_care_management_application/utils/validator.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../controllers/authentication.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isParent = true; 
  Authentication auth = Authentication();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await auth.loginWithGoogle(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await auth.login(context, email, password);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final orientationType = MediaQuery.orientationOf(context);

          if (constraints.maxWidth > 821 ||
              (Orientation.landscape == orientationType)) {
            return _buildLandscapeLogin();
          } else {
            return _buildPotraitLogin();
          }
        },
      ),
    );
  }

  Widget _buildPotraitLogin() {
    final screensize = MediaQuery.sizeOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: screensize.width,
                child: Image.asset('assets/images/login.png', fit: BoxFit.fill),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Wrap(
                  direction: Axis.vertical,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Welcome', style: textTheme.bodyLarge),
                    Text(
                      'Please login to access the page',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Added user type toggle switch
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Caretaker', style: textTheme.bodySmall),
                    Switch(
                      value: _isParent,
                      onChanged: (value) {
                        setState(() {
                          _isParent = value;
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    Text('Parent', style: textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.all(15),
                constraints: BoxConstraints(maxWidth: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: _textfieldWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLogin() {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Form(
        key: _formKey,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: MediaQuery.of(context).size.width *
                  0.9, // 90% of screen width
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1, // Square aspect ratio
                      child: Image.asset(
                        'assets/images/login.png',
                        fit: BoxFit.contain, // Changed to contain
                      ),
                    ),
                  ),
                  const SizedBox(width: 20), // Spacing between image and form
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Please login to access the page',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // User type toggle switch
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Caretaker', style: textTheme.bodyMedium),
                                Switch(
                                  value: _isParent,
                                  onChanged: (value) {
                                    setState(() {
                                      _isParent = value;
                                    });
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                                Text('Parent', style: textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(5),
                            padding:
                                const EdgeInsets.all(16), // Increased padding
                            constraints: const BoxConstraints(maxWidth: 400),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _textfieldWidget(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _textfieldWidget() {
    final textTheme = Theme.of(context).textTheme;

    List<Widget> widgets = [
      Text('Email', style: textTheme.bodyMedium),
      TextFormField(
        style: textTheme.labelLarge,
        controller: _emailController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.email),
          errorStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2.0,
            ),
          ),
          hintText: "Ex: abc@yahoo.com",
          hintStyle: textTheme.labelLarge,
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: Validator.validateEmailAddress,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
      Text('Password', style: textTheme.bodyMedium),
      TextFormField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          errorStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2.0,
            ),
          ),
          hintText: 'Insert your password',
          hintStyle: textTheme.labelLarge,
        ),
        validator: (value) => Validator.validateField(value, 'Password'),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        textInputAction: TextInputAction.done,
      ),
      Gap(5),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleEmailLogin,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CustomLoader(),
                )
              : const Text('Log in', style: TextStyle(fontSize: 16)),
        ),
      ),
      Gap(5),
    ];

    // Only show Google login button if user is parent
    if (_isParent) {
      widgets.addAll([
        Row(children: [
          Expanded(child: Divider()),
          Gap(5),
          Text('or directly login via:'),
          Gap(5),
          Expanded(child: Divider())
        ]),
        Gap(5),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleGoogleLogin,
            icon: GoogleLogo(size: 15),
            label: const Text('Log in with Google'),
          ),
        ),
        Gap(5),
      ]);
    }

    widgets.add(
      Center(
        child: Wrap(
          direction: Axis.horizontal,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Not Registered Yet? |', style: textTheme.labelLarge),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.pushNamed(context, '/register');
                    },
              child: const Text('Click Here'),
            ),
          ],
        ),
      ),
    );

    return widgets;
  }
}
