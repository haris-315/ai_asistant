import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechRecognitionService {
  static final SpeechRecognitionService _instance =
      SpeechRecognitionService._internal();

  factory SpeechRecognitionService() {
    return _instance;
  }

  SpeechRecognitionService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  final StreamController<String> _streamController = StreamController<String>();

  Stream<String> get recognizedTextStream => _streamController.stream;

  Future<void> initialize() async {
    bool available = await _speech.initialize();
    if (available) {
      _startListening();
    } else {
      _streamController.addError('Speech recognition is not available');
    }
  }

  // Start listening for speech
  void _startListening() {
    _speech.listen(onResult: (result) {
      _recognizedText = result.recognizedWords;
      _streamController.add(_recognizedText); // Notify listeners (UI)
    });
    _isListening = true;
  }

  // Stop listening
  void stopListening() {
    _speech.stop();
    _isListening = false;
  }

  // Dispose the stream controller when it's no longer needed
  void dispose() {
    _streamController.close();
  }

  // Check if the service is listening
  bool get isListening => _isListening;
}
