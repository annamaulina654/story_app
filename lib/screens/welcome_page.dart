import 'package:flutter/material.dart';
import 'package:story_app/screens/login_page.dart'; 
import 'package:story_app/screens/register_page.dart'; 
import 'package:story_app/constants/app_colors.dart'; 

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1), 
              Image.asset(
                "assets/images/welcome-bro.png", 
                height: MediaQuery.of(context).size.height * 0.4, 
                fit: BoxFit.contain, 
              ),
              const SizedBox(height: 40),
              Text(
                "Welcome to Story App!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryBlue, 
                  fontSize: 28,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700, 
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "Share your moments, create stories, and connect with people around the world.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.greyishBlue, 
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 60),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: SizedBox(
                  width: double.infinity, 
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue, 
                      side: const BorderSide(color: AppColors.primaryBlue, width: 1.5), 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Sign In',
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
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: SizedBox(
                  width: double.infinity, 
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()), 
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryBlue, width: 1.5), 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.primaryBlue, 
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05), 
            ],
          ),
        ),
      ),
    );
  }
}