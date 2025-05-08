import 'package:ai_asistant/Controller/auth_Controller.dart';
import 'package:ai_asistant/core/services/session_store_service.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:get/get_core/src/get_main.dart';

class NativeBridge {
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.ai_assistant/stt');
  static const EventChannel _eventChannel =
      EventChannel('com.example.ai_assistant/stt_results');

  // Stream to listen for speech recognition results
  static Stream<String>? _speechStream;

  /// Starts the Android STT recognizer
  static Future<bool> startListening() async {
    try {
      AuthController authController = Get.find<AuthController>();
      String authToken = await SecureStorage.getToken() ?? "No Token";
      List<String> projects = authController.projects.map((f) => f.toString()).toList();
      final bool result = await _methodChannel.invokeMethod('startListening',{"authToken" : authToken,"projects" : projects});
      return result;
    } on PlatformException catch (e) {
      print('Failed to start STT: ${e.message}');
      return false;
    }
  }

  /// Stops the Android STT recognizer
  static Future<bool> stopListening() async {
    try {
      final bool result = await _methodChannel.invokeMethod('stopListening');
      return result;
    } on PlatformException catch (e) {
      print('Failed to stop STT: ${e.message}');
      return false;
    }
  }

  /// Checks if the STT recognizer is currently listening
  static Future<bool> isListening() async {
    try {
      final bool result = await _methodChannel.invokeMethod('isListening');
      return result;
    } on PlatformException catch (e) {
      print('Failed to check listening status: ${e.message}');
      return false;
    }
  }

  /// Returns a stream of speech recognition results
  static Stream<String> getSpeechResults() {
    _speechStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as String)
        .handleError((error) {
      print('Error receiving speech results: $error');
      throw error;
    });
    return _speechStream!;
  }
}