import 'dart:ui';

import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/ui/screen/auth/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widget/btn_custumize.dart';
import '../../widget/input_field.dart';
import '../../widget/snackbar.dart';
import '../home/dashboard.dart';
import 'outlook_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController controller = AuthController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
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
                    SizedBox(height: 4.h),

                    Center(
                      child: CircleAvatar(
                        radius: 24.spa,
                        backgroundImage: AssetImage("assets/launchericon.png"),
                      ),
                    ),

                    SizedBox(height: 6.h),

                    Text(
                      'Welcome back!',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22.sp,
                      ),
                    ),

                    SizedBox(height: 1.h),

                    Text(
                      'Please sign in to continue',
                      style: textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),

                    SizedBox(height: 4.h),

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
                    ),

                    SizedBox(height: 1.h),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot Password?',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : CustomButton(
                          title: 'Sign In',
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (passwordController.text.length >= 8) {
                                setState(() => _isLoading = true);
                                bool? response = await controller.LoginUser(
                                  emailController.text.trim(),
                                  passwordController.text.trim(),
                                );
                                setState(() => _isLoading = false);

                                if (response == true) {
                                  emailController.clear();
                                  passwordController.clear();
                                  Get.offAll(() => HomeScreen());
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

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'OR',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 3.h),

                    Center(
                      child: SizedBox(
                        height: 50,
                        width: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            backgroundColor: Colors.white.withValues(alpha: 0),
                          ),
                          onPressed: () async {
                            Get.to(() => OutlookScreen());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset("assets/outlook.png"),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          Get.to(() => RegistrationScreen());
                        },
                        child: RichText(
                          text: TextSpan(
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                            children: [
                              TextSpan(text: 'Don\'t have an account? '),
                              TextSpan(
                                text: 'Sign up',
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
