import 'package:flutter/material.dart' show GlobalKey, ScaffoldMessengerState;

class SnackbarService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();
}
