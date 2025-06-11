import 'dart:async';

import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/shared/functions/show_toast.dart';
import 'package:ai_asistant/data/models/service_models/assistant_service_model.dart';
import 'package:ai_asistant/data/models/service_models/voice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class NativeBridge {
  static AuthController authController = Get.find<AuthController>();
  static const MethodChannel _methodChannel = MethodChannel(
    'com.example.ai_assistant/stt',
  );

  static Future<bool> startListening() async {
    try {
      String authToken = await SettingsService.getToken() ?? "No Token";
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

  static Future<bool> dumpMails(List<String> mails) async {
    try {
      final bool result = await _methodChannel.invokeMethod('dumpMails', {
        "mails": mails,
      });
      return result;
    } catch (e) {
      print("There was an error while sending emails ${e.toString()}");
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

  static Future<bool> isListening() async {
    try {
      final bool result = await _methodChannel.invokeMethod('isListening');
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<String> getDbPath() async {
    try {
      final String result = await _methodChannel.invokeMethod('getDbPath');
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
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
        mailsSyncHash: "",
        recognizedText: "There was an error!",
        initializing: false,
        isWarmingTts: false,
      );
    }
  }

  static Future setKeys({
    required String oAIKey,
    required String aAIkey,
  }) async {
    try {
      await _methodChannel.invokeMethod("setKeys", {
        "oaikey": oAIKey,
        "aaikey": aAIkey,
      });
    } catch (e) {
      if (kDebugMode) {
        print("ErrorHint: $e");
      }
      showToast(message: "API Error!");
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

  static Future<Map<dynamic, dynamic>> setPorcupineKey(String key) async {
    try {
      final Map<dynamic, dynamic> result = await _methodChannel.invokeMethod(
        "setPorcupineKey",
        {"akey": key},
      );
      // print(result);
      return result;
    } on PlatformException catch (_) {
      rethrow;
    }
  }

  /// Returns a stream of speech recognition results
}
