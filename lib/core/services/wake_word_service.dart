// import 'dart:ui';

// import 'package:flutter/services.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:porcupine_flutter/porcupine_manager.dart';

// @pragma('vm:entry-point')
// class JarvisWakeWordService {
//   static final JarvisWakeWordService _instance =
//       JarvisWakeWordService._internal();

//   factory JarvisWakeWordService() => _instance;

//   JarvisWakeWordService._internal();

//   final FlutterBackgroundService _service = FlutterBackgroundService();
//   static const _platform = MethodChannel('flutter_background_service');
//   @pragma('vm:entry-point')
//   Future<void> initialize() async {
//     await _service.configure(
//       androidConfiguration: AndroidConfiguration(
//         onStart: _onStart,
//         autoStart: true,
//         isForegroundMode: true,
//         initialNotificationTitle: 'Jarvis is listening...',
//         initialNotificationContent: 'Say "Hey Jarvis"',
//       ),
//       iosConfiguration: IosConfiguration(
//         autoStart: true,
//         onForeground: _onStart,
//         onBackground: (_) async => true,
//       ),
//     );

//     await _service.startService();
//   }
//   @pragma('vm:entry-point')
//   static void _onStart(ServiceInstance service) async {
//     DartPluginRegistrant.ensureInitialized();

//     if (await Permission.microphone.request().isGranted) {
//       final porcupine = await PorcupineManager.fromKeywordPaths(
//         "k0f/n6QPirEXI/GzBJp977eoIAD7GbMW8BRdmUqGqMqEgOwgwbkoMA==",

//         ["assets/keywords/hey_jarvis.pv"],
//         (index) {
//           print("Wake word detected: Hey Jarvis");
//           _bringAppToFront();
//         },
//         modelPath: 'assets/models/porcupine_params.pv',
//         sensitivities: [0.7],
//       );

//       await porcupine.start();
//     } else {
//       print("Microphone permission denied.");
//     }
//   }
//   @pragma('vm:entry-point')
//   static Future<void> _bringAppToFront() async {
//     try {
//       await _platform.invokeMethod("bringToFront");
//     } catch (e) {
//       print("Failed to bring app to front: $e");
//     }
//   }
// }
