import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final Function(String)? onTextRecognized;

  SpeechService({this.onTextRecognized});

  Future<bool> initialize() async {
    return await _speech.initialize();
  }

  void startListening() {
    _speech.listen(
      onResult: (result) {
        if (result.finalResult && onTextRecognized != null) {
          onTextRecognized!(result.recognizedWords.toLowerCase());
        }
      },
      listenOptions: stt.SpeechListenOptions(partialResults: false),
      listenFor: Duration(minutes: 30),
      pauseFor: Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  void stopListening() {
    _speech.stop();
  }

  void dispose() {
    _speech.cancel();
  }
}
