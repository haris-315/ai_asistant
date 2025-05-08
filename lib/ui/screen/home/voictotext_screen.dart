// ignore_for_file: unused_field

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../widget/appbar.dart';
import '../../widget/drawer.dart';

class VoiceToTextScreen extends StatefulWidget {
  const VoiceToTextScreen({super.key});

  @override
  _VoiceToTextScreenState createState() => _VoiceToTextScreenState();
}

class _VoiceToTextScreenState extends State<VoiceToTextScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "Start speaking...";
  bool _speechAvailable = false;
  final List<int> _waveData = [];
  late FlutterSoundRecorder _recorder;
  bool _isRecording = false;
  Timer? _waveformTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _recorder = FlutterSoundRecorder();
    _initSpeech();
    _initRecorder();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print("Speech Status: $status");
        if (status == "notListening" || status == "done") {
          setState(() {
            _isListening = false;
            _isRecording = false;
          });
        }
      },
      onError: (error) {
        print("Speech Error: $error");
        setState(() {
          _isListening = false;
          _isRecording = false;
        });
      },
    );
    print("Speech Available: $available");
    setState(() {
      _speechAvailable = available;
    });
  }

  String? _lastWords;
  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();
      print("Recorder Initialized Successfully");
    } catch (e) {
      print("Recorder Initialization Failed: $e");
    }
  }

  // void _onSpeechResult(SpeechRecognitionResult result) {
  //   setState(() {
  //     _lastWords = result.recognizedWords;
  //     // _text = _lastWords!;
  //     _text += " " + _lastWords!;
  //
  //     print("_lastWords ::$_lastWords");
  //   });
  // }
  void _onSpeechResult(SpeechRecognitionResult result) {
    String recognizedText = result.recognizedWords.toLowerCase();

    setState(() {
      if (recognizedText.contains("dear stop")) {
        _stopListening();
        return;
      }

      if (recognizedText.contains("dear on")) {
        _startListening();
        return;
      }

      if (_lastWords == null || recognizedText.length > _lastWords!.length) {
        String newText =
            recognizedText.replaceFirst(_lastWords ?? "", "").trim();
        _text += " $newText";
      }

      _lastWords = recognizedText;
      print("_lastWords :: $_lastWords");
    });
  }

  void _startListening() async {
    await _speech.listen(onResult: _onSpeechResult);
  }

  void _stopListening() async {
    setState(() {
      _isListening = false;
      _isRecording = false;
    });
    print("Stopped Listening. _isListening: $_isListening");

    try {
      await _recorder.stopRecorder();
      print("Recording Stopped");
    } catch (e) {
      print("Recording Stop Failed: $e");
    }

    _waveformTimer?.cancel();
    _waveData.clear();
    await _speech.stop();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "AI Assistant",
        onNotificationPressed: () {
          print("Notification Clicked!");
        },
        onProfilePressed: () {
          print("Profile Clicked!");
        },
      ),
      drawer: SideMenu(),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Builder(
                    builder: (context) {
                      return Container(
                        height: 6.5.h,
                        width: 13.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey, width: 1),
                          color: Colors.white,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.menu, color: Colors.black),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),

            Text(
              _isListening ? "Listening..." : "Tap the mic to start recording",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),

            Container(
              height: 45.h,
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Text(_text, style: TextStyle(fontSize: 16)),
            ),

            SizedBox(height: 5.h),

            Container(
              height: 1.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CustomPaint(painter: WaveformPainter(_waveData)),
            ),

            Spacer(),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),

                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.red,
                      size: 40,
                    ),
                    onPressed: () {
                      print("Button Clicked! Listening: $_isListening");

                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                  ),

                  SizedBox(width: 3.w),
                  IconButton(
                    icon: Icon(
                      Icons.play_circle_outline_outlined,
                      color: Colors.black,
                      size: 40,
                    ),
                    onPressed: () {
                      print("Play Recorded Audio");
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<int> waveData;
  WaveformPainter(this.waveData);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;

    double widthStep = size.width / waveData.length;
    for (int i = 0; i < waveData.length; i++) {
      double x = i * widthStep;
      double y = size.height / 0.2;
      double height = waveData[i].toDouble();
      canvas.drawLine(Offset(x, y - height), Offset(x, y + height), paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) => true;
}
