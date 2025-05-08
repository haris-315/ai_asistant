import 'package:flutter/services.dart';

class WakeWordService {
  static const platform = MethodChannel('com.yourdomain/wakeword');

  static Future<void> startService() async {
    try {
      final result = await platform.invokeMethod('startService');
      print(result);
    } catch (e) {
      print(e);
      throw "Awake service failed to start";
    }
  }
}
