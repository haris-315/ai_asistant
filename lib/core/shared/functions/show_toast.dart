import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast({required String message, Toast length = Toast.LENGTH_LONG}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: length,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.blueGrey,
    textColor: Colors.white,
    fontSize: 15.0,
  );
}
