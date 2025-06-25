import 'package:flutter/material.dart';
import 'package:story_app/screens/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:story_app/widgets/custom_text_form_field.dart';
import 'package:story_app/services/auth_service.dart';
import 'package:story_app/constants/app_colors.dart';

class RegisterForm extends StatefulWidget {
  final PageController? controller;

  const RegisterForm({super.key, this.controller});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  bool rememberMe = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  final ValueNotifier<String?> _firebaseEmailError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _firebasePasswordError = ValueNotifier<String?>(null);

  final AuthService _authService = AuthService();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();

    _firebaseEmailError.dispose();
    _firebasePasswordError.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    _firebaseEmailError.value = null;
    _firebasePasswordError.value = null;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      UserCredential userCredential = await _authService.registerUserWithFirebase(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await _authService.sendFirebaseEmailVerification(user);
        await _authService.registerUserInMySQL(
          firebaseUid: user.uid,
          username: _nameController.text.trim(),
          email: _emailController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please check your email for verification.'),
              backgroundColor: Colors.green,
            ),
          );
          if (widget.controller != null) {
            widget.controller!.animateToPage(0, duration: const Duration(milliseconds: 500), curve: Curves.ease);
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        _firebasePasswordError.value = 'Password is too weak.';
        message = 'Password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        _firebaseEmailError.value = 'This email is already in use.';
        message = 'This email is already in use.';
      } else if (e.code == 'invalid-email') {
        _firebaseEmailError.value = 'Invalid email format.';
        message = 'Invalid email format.';
      } else {
        message = 'An error occurred during registration: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register. Please try again or use another email. (${e.toString()})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name must be filled';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email must be filled';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Invalid email format';
    }
    return null; 
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password must be filled';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm password must be filled';
    }
    if (value != _passwordController.text) {
      return 'Passwords don\'t match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Image.asset(
                'assets/images/mobile-login.png',
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.35,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sign Up",
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 27,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextFormField(
                      controller: _nameController,
                      labelText: 'Full Name',
                      errorText: ValueNotifier(_nameError),
                      validator: _validateName, 
                      onChanged: (value) {
                        setState(() {
                          _nameError = _validateName(value);
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                    CustomTextFormField(
                      controller: _emailController,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      errorText: ValueNotifier(_emailError),
                      validator: _validateEmail,
                      onChanged: (value) {
                        setState(() {
                          _emailError = _validateEmail(value);
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                    CustomTextFormField(
                      controller: _passwordController,
                      labelText: 'Password',
                      obscureText: _obscurePassword,
                      errorText: ValueNotifier(_passwordError),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.greyishBlue),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: _validatePassword,
                      onChanged: (value) {
                        setState(() {
                          _passwordError = _validatePassword(value);
                          if (_confirmController.text.isNotEmpty) {
                            _confirmPasswordError = _validateConfirmPassword(_confirmController.text);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                    CustomTextFormField(
                      controller: _confirmController,
                      labelText: 'Confirm Password',
                      obscureText: _obscureConfirmPassword,
                      errorText: ValueNotifier(_confirmPasswordError),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: AppColors.greyishBlue),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: _validateConfirmPassword,
                      onChanged: (value) {
                        setState(() {
                          _confirmPasswordError = _validateConfirmPassword(value);
                        });
                      },
                    ),
                    const SizedBox(height: 25),

                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _submitRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            elevation: 0,
                          ),
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(
                            color: AppColors.greyishBlue,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2.5),
                        InkWell(
                          onTap: () {
                            if (widget.controller != null) {
                              widget.controller!.animateToPage(
                                0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.ease,
                              );
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                              );
                            }
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}