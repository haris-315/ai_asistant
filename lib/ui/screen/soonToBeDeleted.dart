import 'dart:async';

import 'package:ai_asistant/core/services/native_bridge.dart';
import 'package:flutter/material.dart';

class Soontobedeleted extends StatefulWidget {
  const Soontobedeleted({super.key});

  @override
  State<Soontobedeleted> createState() => _SoontobedeletedState();
}

class _SoontobedeletedState extends State<Soontobedeleted> {
  String _recognizedText = 'Waiting for speech...';
  bool _isListening = false;
  StreamSubscription<String>? _speechSubscription;

  @override
  void initState() {
    super.initState();
    // Start listening to the speech результатов stream
    _speechSubscription = NativeBridge.getSpeechResults().listen(
      (text) {
        setState(() {
          _recognizedText = text;
        });
      },
      onError: (error) {
        setState(() {
          _recognizedText = 'Error: $error';
        });
      },
    );
  }

  @override
  void dispose() {
    _speechSubscription?.cancel();
    NativeBridge.stopListening();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      final success = await NativeBridge.stopListening();
      if (success) {
        setState(() {
          _isListening = false;
          _recognizedText = 'Stopped listening';
        });
      }
    } else {
      final success = await NativeBridge.startListening();
      if (success) {
        setState(() {
          _isListening = true;
          _recognizedText = 'Listening...';
        });
      } else {
        setState(() {
          _recognizedText = 'Failed to start listening';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speech Recognition')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _recognizedText,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _toggleListening,
              icon: const Icon(Icons.mic),
              label: Text(_isListening ? "Stop!" : 'Wake Assistant'),
            ),
            // OutlinedButton.icon(
            //   onPressed: _isListening ? _toggleListening : null,
            //   icon: const Icon(Icons.stop),
            //   label: const Text('Stop!'),
            // ),
          ],
        ),
      ),
    );
  }
}
