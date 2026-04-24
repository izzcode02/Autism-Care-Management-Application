import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/screen/authentication/controllers/authentication.dart';
import 'package:autism_care_management_application/screen/authentication/views/verify_email.dart';
import 'package:autism_care_management_application/utils/validator.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _showRoleSelection = true;
  String _selectedRole = '';

  // Add form key for validation
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      backgroundColor: Colors.green[50],
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: _showRoleSelection
              ? _buildRoleSelection()
              : _buildRegistrationForm(),
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'I am a...',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              setState(() {
                _selectedRole = 'Parent';
                _showRoleSelection = false;
              });
            },
            child: const Text('Parent', style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              setState(() {
                _selectedRole = 'Caretaker';
                _showRoleSelection = false;
              });
            },
            child: const Text('Caretaker', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey, // Assign the form key
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _showRoleSelection = true;
                    });
                  },
                ),
                Text(
                  'Registering as $_selectedRole',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._textfieldWidget(),
          ],
        ),
      ),
    );
  }

  List<Widget> _textfieldWidget() {
    final textTheme = Theme.of(context).textTheme;

    return [
      Text('Email', style: textTheme.bodyMedium),
      const SizedBox(height: 5),
      TextFormField(
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
      const SizedBox(height: 15),
      Text(_selectedRole == "Parent"? 'Full Name' : "Autism Centre Name", style: textTheme.bodyMedium),
      const SizedBox(height: 5),
      TextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.person),
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
          hintText: _selectedRole == "Parent"
              ? "Ex: Ali bin Abu"
              : "Ex: Pusat Autism ",
          hintStyle: textTheme.labelLarge,
        ),
        keyboardType: TextInputType.name,
        textInputAction: TextInputAction.next,
        validator: (value) => Validator.validateField(value, 'full name'),
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
      const SizedBox(height: 15),
      Text('Password', style: textTheme.bodyMedium),
      const SizedBox(height: 5),
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
        validator: Validator.validatePassword,
        textInputAction: TextInputAction.done,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
      const SizedBox(height: 15),
      Text('Confirm Password', style: textTheme.bodyMedium),
      const SizedBox(height: 5),
      TextFormField(
        controller: _confirmPasswordController,
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
          hintText: 'Confirm your password',
          hintStyle: textTheme.labelLarge,
        ),
        validator: (value) {
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
        textInputAction: TextInputAction.done,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
      const SizedBox(height: 25),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  // Validate the form first
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true;
                    });

                    // Proceed only if form is valid
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VerifyEmailScreen(
                          name: _nameController.text.trim(),
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                          roles: _selectedRole,
                        ),
                      ),
                    );

                    setState(() => _isLoading = false);
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CustomLoader(),
                )
              : const Text('Register', style: TextStyle(fontSize: 18)),
        ),
      ),
    ];
  }
}
