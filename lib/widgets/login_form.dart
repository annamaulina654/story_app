import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:story_app/screens/register_page.dart';
import 'package:story_app/widgets/custom_text_form_field.dart'; 
import 'package:story_app/services/auth_service.dart'; 
import 'package:story_app/constants/app_colors.dart'; 
import 'package:story_app/screens/feed_page.dart';

class LoginFormPage extends StatefulWidget { 
  final PageController? controller;

  const LoginFormPage({super.key, this.controller});

  @override
  State<LoginFormPage> createState() => _LoginFormPageState(); 
}

class _LoginFormPageState extends State<LoginFormPage> { 
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true; 
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService(); 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; 
    });

    try {
      final userData = await _authService.loginUserWithFirebaseAndMySQL(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil dan email terverifikasi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FeedPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Email atau password salah.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      } else if (e.code == 'too-many-requests') {
        message = 'Terlalu banyak percobaan login. Coba lagi nanti.';
      } else if (e.code == 'network-request-failed') {
        message = 'Koneksi internet terputus. Silakan cek jaringan Anda.';
      } else if (e.code == 'email-not-verified') { 
        message = e.message!;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Kirim Ulang Verifikasi',
                onPressed: () async {
                  await _authService.resendEmailVerification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email verifikasi telah dikirim ulang.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
        setState(() { _isLoading = false; }); 
        return;
      }
      else {
        message = 'Terjadi kesalahan saat login: ${e.message}';
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
      print('Caught unexpected error during login: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan tidak terduga: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Image.asset(
                "assets/images/login-bro.png",
                width: size.width,
                height: size.height * 0.35,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Log In",
                      style: TextStyle(
                        color: AppColors.primaryBlue, 
                        fontSize: 27,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextFormField(
                      controller: _emailController,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email is required';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Invalid email format';
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    CustomTextFormField(
                      controller: _passwordController,
                      labelText: 'Password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.greyishBlue, 
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),

                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue, 
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Sign In",
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
                          "Don’t have an account?",
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
                                1,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.ease,
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterPage()),
                              );
                            }
                          },
                          child: const Text(
                            'Sign Up',
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