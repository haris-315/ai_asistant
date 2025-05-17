
// ignore_for_file: library_private_types_in_public_api

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
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cpasswordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();




  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child:
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 5.h),
                SizedBox(
                  width: 80.w,
                  height: 24.h,

                  child: Image.asset('assets/Illustration.png'),
                ),
                SizedBox(height: 3.h),


                CustomFormTextField(
                  error: "Your Name",
                  label: "Your Name",
                  icon: Icons.person_outline_outlined,
                  controller: fullNameController,
                  keyboardType: TextInputType.text,
                ),
                // SizedBox(height: 1.5.h),
                // CustomFormTextField(
                //   error: "Date of Birth",
                //   label: "Date of Birth",
                //   icon: Icons.calendar_today,
                //   controller: dateOfBirthController,
                //   isDateField: true,
                // ),
                SizedBox(height: 1.5.h),

                CustomFormTextField(
                  error: "Email",
                  label: "Email",
                  icon: Icons.email_outlined,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  isEmail: true,
                ),
                SizedBox(height: 1.5.h),
                CustomFormTextField(
                  error: "Password",
                  label: "Password",
                  icon: Icons.lock_outline_rounded,
                  controller: passwordController,
                  isPassword: true,
                  maxLength: 16,
                  showPasswordStrength: true,

                ),

                SizedBox(height: 1.5.h),
                 CustomFormTextField(
                  error: "Confirm Password",
                  label: "Confirm Password",
                  icon: Icons.lock_outline_rounded,
                  controller: cpasswordController,
                  isPassword: true,
                  maxLength: 16,
                  showPasswordStrength: true,
                ),
                SizedBox(height: 1.5.h),

                CustomButton(
                  title: 'Register',
                  backgroundColor: Colors.blue,
                  textColor: Colors.white,
                  borderColor: Colors.blue,
                  borderRadius: 8.0,
                  height: 50.0,
                  width: double.infinity,
                  onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                  if(passwordController.text == cpasswordController.text){
                    if(passwordController.text.length >= 8 && cpasswordController.text.length >= 8)
                    {
                      bool? response;
                      response =  await controller.Registration(fullNameController.text, emailController.text, passwordController.text);

                      if(response == true){
                        fullNameController.clear();
                        emailController.clear();
                        passwordController.clear();
                        cpasswordController.clear();

                        Get.to(() => LoginScreen());
                      }

                    }else{
                      showCustomSnackbar(
                        title: "Error",
                        message: "Your password Length will be min 8",
                        backgroundColor: Colors.red,
                        icon: Icons.error,
                      );
                    }


                  }
                  else{
                    showCustomSnackbar(
                      title: "Error",
                      message: "Your password is not match",
                      backgroundColor: Colors.red,
                      icon: Icons.error,
                    );
                  }


                    }}

                ),

                // const Spacer(),
                SizedBox(height: 3.h,),
                TextButton(
                  onPressed: () {
                    Get.to(() => LoginScreen());
                  },
                  child: RichText(
                    text: TextSpan(
                      style: textTheme.bodyLarge?.copyWith(
                          color: Colors.black, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(text: 'Already have an account?? '),
                        TextSpan(
                          text: 'Sign in',
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
      ),
    );
  }
}
