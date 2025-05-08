import 'package:ai_asistant/core/services/snackbar_service.dart';
import 'package:flutter/material.dart';

void showSnackBar({
  required BuildContext context,
  bool isError = false,
  required String message,
}) {
  SnackbarService.messengerKey.currentState!
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red : Colors.green,
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
}
