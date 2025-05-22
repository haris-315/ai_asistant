import 'dart:async';

import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/core/services/session_store_service.dart';
import 'package:ai_asistant/data/models/service_models/assistant_service_model.dart';
import 'package:ai_asistant/data/models/service_models/voice.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class NativeBridge {
  static AuthController authController = Get.find<AuthController>();
  static const MethodChannel _methodChannel = MethodChannel(
    'com.example.ai_assistant/stt',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.example.ai_assistant/stt_results',
  );

  // Stream to listen for speech recognition results
  static Stream<String>? _speechStream;

  /// Starts the Android STT recognizer
  static Future<bool> startListening() async {
    try {
      String authToken = await SecureStorage.getToken() ?? "No Token";
      List<String> projects =
          authController.projects.map((f) => f.toString()).toList();
      final bool result = await _methodChannel.invokeMethod('startListening', {
        "authToken": authToken,
        "projects": projects,
      });
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Stops the Android STT recognizer
  static Future<bool> stopListening() async {
    try {
      final bool result = await _methodChannel.invokeMethod('stopListening');
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Checks if the STT recognizer is currently listening
  static Future<bool> isListening() async {
    try {
      final bool result = await _methodChannel.invokeMethod('isListening');
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<AssistantServiceModel> getInfo() async {
    try {
      final Map result = await _methodChannel.invokeMethod('getInfo', {
        'tasks':
            authController.task
                .where(
                  (t) =>
                      t.reminder_at != null &&
                      t.reminder_at!.isAfter(DateTime.now()),
                )
                .map((tm) => tm.toSpecificMap())
                .toList(),
      });
      return AssistantServiceModel.fromMap(result);
    } on PlatformException catch (_) {
      return AssistantServiceModel(
        isBound: false,
        isStoped: false,
        isStandBy: false,

        recognizedText: "There was an error!",
        initializing: false,
        isWarmingTts: false,
      );
    }
  }

  static Future<List<Voice>> getOrSetAvailableVoices(String? model) async {
    try {
      final List result = await _methodChannel.invokeMethod(
        model != null ? "setVoice" : 'getVoices',
        model != null ? {"voice": model} : null,
      );
      // print(result);
      return result.map((v) => Voice.fromMap(v)).toList();
    } on PlatformException catch (_) {
      rethrow;
    }
  }

  static Future<Map<dynamic, dynamic>> setKey(String key) async {
    try {
      final Map<dynamic, dynamic> result = await _methodChannel.invokeMethod(
        "setKey",
        {"akey": key},
      );
      // print(result);
      return result;
    } on PlatformException catch (_) {
      rethrow;
    }
  }

  /// Returns a stream of speech recognition results
  static Stream<String> getSpeechResults() {
    _speechStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as String)
        .handleError((error) {
          throw error;
        });
    return _speechStream!;
  }
}
