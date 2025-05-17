import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/ui/screen/auth/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widget/btn_custumize.dart';
import '../../widget/icon_btn_customized.dart';
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 4.h),
              Container(
                width: 80.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/loginimage.png'),
              ),
              SizedBox(height: 2.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sign In',

                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Align(
                alignment: Alignment.centerLeft,

                child: Text(
                  'Please login to continue to your account.',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black45,
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              CustomFormTextField(
                error: "Email",
                label: "Email",
                icon: Icons.email,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                isEmail: true,
              ),
              SizedBox(height: 1.5.h),
              CustomFormTextField(
                error: "Password",
                label: "Password",
                icon: Icons.lock,
                controller: passwordController,
                isPassword: true,
                maxLength: 16,
                showPasswordStrength: true,
              ),
              SizedBox(height: 1.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot Password?',
                    style: textTheme.bodySmall?.copyWith(color: Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),
              CustomButton(
                title: 'Sign in',
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (passwordController.text.length >= 8) {
                      bool? response;
                      response = await controller.LoginUser(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      );
                      if (response == true) {
                        emailController.clear();
                        passwordController.clear();
                        Get.offAll(() => HomeScreen());
                      }

                      // _loginUser();
                    } else {
                      showCustomSnackbar(
                        title: "Error",
                        message: "Your password Length will be min 8",
                        backgroundColor: Colors.red,
                        icon: Icons.error,
                      );
                    }
                  }
                },
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                borderColor: Colors.blue,
                borderRadius: 8.0,
                height: 50.0,
                width: double.infinity,
              ),
              SizedBox(height: 1.5.h),
              Row(
                children: <Widget>[
                  Expanded(child: Divider(color: Colors.grey[400])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400])),
                ],
              ),
              SizedBox(height: 1.5.h),
              CustomIconButton(
                title: 'Proceed with Outlook',
                onPressed: () async {
                  // String? link;
                  // link  =  await controller.outLooklogin();
                  // print("link ::::$link");
                  // Get.to(() => OutlookScreen(link: link!));
                  Get.to(() => OutlookScreen());

                  // Get.to(() => HomeScreen());
                },
                assetPath: "assets/outlook.png",
                backgroundColor: Colors.white,
                textColor: Colors.black,
                borderColor: Colors.grey,
                borderRadius: 8.0,
                height: 50.0,
                width: double.infinity,
              ),

              const Spacer(),
              TextButton(
                onPressed: () {
                  Get.to(() => RegistrationScreen());
                },
                child: RichText(
                  text: TextSpan(
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(text: 'Need an account? '),
                      TextSpan(
                        text: 'Create one',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
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
    );
  }
}
