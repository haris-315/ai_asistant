import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../Controller/auth_controller.dart';
import '../../widget/btn_custumize.dart';
import '../../widget/input_field.dart';
import '../../widget/snackbar.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final AuthController controller = AuthController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cpasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/splash_loading.webp"),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(color: Colors.transparent),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: 2.h),

                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),

                    SizedBox(height: 2.h),

                    Center(
                      child: CircleAvatar(
                        radius: 24.spa,
                        backgroundImage: AssetImage(
                          "assets/launchericon.png",
                          
                        ),
                      ),
                    ),

                    SizedBox(height: 1.h),

                    Center(
                      child: Text(
                        'Join us to get started',
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    CustomFormTextField(
                      error: "Please enter your full name",
                      label: "Full Name",
                      icon: Icons.person_outline,
                      controller: fullNameController,
                      keyboardType: TextInputType.name,
                    ),

                    SizedBox(height: 2.h),

                    CustomFormTextField(
                      error: "Please enter a valid email",
                      label: "Email Address",
                      icon: Icons.email_outlined,
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      isEmail: true,
                    ),

                    SizedBox(height: 2.h),

                    CustomFormTextField(
                      error: "Password must be at least 8 characters",
                      label: "Password",
                      icon: Icons.lock_outline,
                      controller: passwordController,
                      isPassword: true,
                      maxLength: 16,
                      showPasswordStrength: true,
                    ),

                    SizedBox(height: 2.h),

                    CustomFormTextField(
                      error: "Passwords must match",
                      label: "Confirm Password",
                      icon: Icons.lock_outline,
                      controller: cpasswordController,
                      isPassword: false,
                      maxLength: 16,
                    ),

                    SizedBox(height: 4.h),

                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : CustomButton(
                          title: 'Create Account',
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (passwordController.text ==
                                  cpasswordController.text) {
                                if (passwordController.text.length >= 8) {
                                  setState(() => _isLoading = true);
                                  bool? response =
                                      await controller.Registration(
                                        fullNameController.text,
                                        emailController.text,
                                        passwordController.text,
                                      );
                                  setState(() => _isLoading = false);

                                  if (response == true) {
                                    fullNameController.clear();
                                    emailController.clear();
                                    passwordController.clear();
                                    cpasswordController.clear();
                                    Get.to(() => LoginScreen());
                                  }
                                } else {
                                  showCustomSnackbar(
                                    title: "Error",
                                    message:
                                        "Password must be at least 8 characters",
                                    backgroundColor: Colors.red,
                                    icon: Icons.error,
                                  );
                                }
                              } else {
                                showCustomSnackbar(
                                  title: "Error",
                                  message: "Passwords do not match",
                                  backgroundColor: Colors.red,
                                  icon: Icons.error,
                                );
                              }
                            }
                          },
                          backgroundColor: Colors.blueAccent,
                          textColor: Colors.white,
                          borderColor: Colors.blueAccent,
                          borderRadius: 12.0,
                          height: 45.0,
                          width: double.infinity,
                        ),

                    SizedBox(height: 3.h),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          Get.to(() => LoginScreen());
                        },
                        child: RichText(
                          text: TextSpan(
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                            children: [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign in',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
