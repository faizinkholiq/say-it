import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize();
    return _isAvailable;
  }

  void listen({required Function(String) onResult}) {
    if (_isAvailable) {
      _speech.listen(onResult: (result) => onResult(result.recognizedWords));
    }
  }

  void stop() => _speech.stop();
  bool isListening() => _speech.isListening;
}
