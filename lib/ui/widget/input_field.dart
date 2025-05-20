// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomFormTextField extends StatefulWidget {
  final String label;
  final IconData? icon;
  final String? imageiconAsset;
  final IconData? suffixIcon;
  final TextEditingController controller;
  final bool isPassword;
  final bool isEmail;
  final bool isDateField;
  final double height;
  final double width;
  final double borderRadius;
  final Color borderColor;
  final TextInputType keyboardType;
  final int maxLength;
  final int maxLines;
  final bool showPasswordStrength;
  final String? error;

  const CustomFormTextField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.imageiconAsset,
    this.suffixIcon,
    this.isPassword = false,
    this.isEmail = false,
    this.isDateField = false, // Default to false
    this.height = 55.0,
    this.width = double.infinity,
    this.borderRadius = 12.0,
    this.borderColor = Colors.blue,
    this.keyboardType = TextInputType.text,
    this.maxLength = 560,
    this.maxLines = 1,
    this.showPasswordStrength = false,
    this.error,
  });

  @override
  _CustomFormTextFieldState createState() => _CustomFormTextFieldState();
}

class _CustomFormTextFieldState extends State<CustomFormTextField> {
  bool isObscured = true;
  String passwordStrength = "";
  Color strengthColor = Colors.red;
  String? emailError;

  void _checkPasswordStrength(String password) {
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecialCharacter = RegExp(
      r'[!@#\$%^&*(),.?":{}|<>]',
    ).hasMatch(password);

    int strengthCount =
        (hasUppercase ? 1 : 0) +
        (hasLowercase ? 1 : 0) +
        (hasDigit ? 1 : 0) +
        (hasSpecialCharacter ? 1 : 0);

    if (password.isEmpty) {
      setState(() {
        passwordStrength = "";
        strengthColor = Colors.transparent;
      });
    } else if (password.length < 8) {
      setState(() {
        passwordStrength = "Too Short";
        strengthColor = Colors.red;
      });
    } else if (strengthCount == 4) {
      setState(() {
        passwordStrength = "Strong";
        strengthColor = Colors.green;
      });
    } else if (strengthCount == 3) {
      setState(() {
        passwordStrength = "Medium";
        strengthColor = Colors.orange;
      });
    } else {
      setState(() {
        passwordStrength = "Weak";
        strengthColor = Colors.red;
      });
    }
  }

  void _validateEmail(String email) {
    final emailPattern = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );

    setState(() {
      if (email.isEmpty) {
        emailError = null;
      } else if (!emailPattern.hasMatch(email)) {
        emailError = "Invalid email format";
      } else {
        emailError = null;
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    setState(() {
      widget.controller.text = DateFormat('yyyy-MM-dd').format(picked!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: SizedBox(
            width: widget.width,
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.isPassword ? isObscured : false,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLength,
              maxLines: widget.maxLines,
              readOnly: widget.isDateField,
              onTap: widget.isDateField ? () => _selectDate(context) : null,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "${widget.error} is required";
                }
                return null;
              },
              onChanged: (text) {
                if (widget.isPassword && widget.showPasswordStrength) {
                  _checkPasswordStrength(text);
                }
                if (widget.isEmail) {
                  _validateEmail(text);
                }
              },
              decoration: InputDecoration(
                labelText: widget.label,
                prefixIcon:
                    widget.isDateField
                        ? Icon(Icons.calendar_today)
                        : (widget.icon != null
                            ? Icon(widget.icon)
                            : (widget.imageiconAsset != null
                                ? Image.asset(
                                  widget.imageiconAsset!,
                                  height: 24,
                                  width: 24,
                                  fit: BoxFit.contain,
                                )
                                : null)),
                suffixIcon:
                    widget.isPassword
                        ? IconButton(
                          icon: Icon(
                            isObscured
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed:
                              () => setState(() => isObscured = !isObscured),
                        )
                        : (widget.suffixIcon != null
                            ? Icon(widget.suffixIcon)
                            : null),
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(color: widget.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                errorText: emailError,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 12,
                ),
              ),
            ),
          ),
        ),
        if (widget.isPassword && widget.showPasswordStrength)
          Padding(
            padding: const EdgeInsets.only(top: 5.0, left: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passwordStrength,
                  style: TextStyle(
                    color: strengthColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    _buildStrengthIndicator(
                      1,
                      passwordStrength == "Weak" ||
                          passwordStrength == "Medium" ||
                          passwordStrength == "Strong",
                    ),
                    SizedBox(width: 4),
                    _buildStrengthIndicator(
                      2,
                      passwordStrength == "Medium" ||
                          passwordStrength == "Strong",
                    ),
                    SizedBox(width: 4),
                    _buildStrengthIndicator(3, passwordStrength == "Strong"),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStrengthIndicator(int level, bool isActive) {
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: isActive ? strengthColor : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}
