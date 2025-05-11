import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showCustomSnackbar({
  required String title,
  required String message,
  required Color backgroundColor,
  SnackPosition snackPosition = SnackPosition.TOP,
  IconData? icon,
}) {
  Get.snackbar(
    title,
    message,
    snackPosition: snackPosition,
    backgroundColor: backgroundColor,
    colorText: Colors.white,
    borderRadius: 8,
    margin: EdgeInsets.all(10),
    icon: Icon(icon ?? Icons.info, color: Colors.white),
    titleText: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    messageText: Text(
      message,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );
}
