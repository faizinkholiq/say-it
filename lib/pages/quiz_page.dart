import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_state.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Speech recognition failed to initialize"),
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to only rebuild parts that need state updates
    return Consumer<QuizState>(
      builder: (context, quizState, child) {
        final currentAlphabet = _getCurrentAlphabet();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Level ${quizState.currentLevel} - '
              'Question ${quizState.currentQuestionIndex + 1}/10',
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Pronounce this letter:'),
                const SizedBox(height: 30),
                // Only this part will rebuild when alphabet changes
                _buildAlphabetDisplay(currentAlphabet),
                const SizedBox(height: 50),
                _buildSpeechButton(context, quizState, currentAlphabet),
                if (_lastWords.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'You said: $_lastWords',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlphabetDisplay(String alphabet) {
    return Text(
      alphabet,
      style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSpeechButton(
    BuildContext context,
    QuizState quizState,
    String currentAlphabet,
  ) {
    return ElevatedButton(
      onPressed: () => _handleSpeechButton(quizState, currentAlphabet),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      ),
      child: _isListening
          ? const Text('Listening...')
          : const Text('Start Speaking'),
    );
  }

  String _getCurrentAlphabet() {
    final alphabets = Provider.of<QuizState>(
      context,
      listen: false,
    ).getAlphabetsForLevel();
    final index = Provider.of<QuizState>(
      context,
      listen: false,
    ).currentQuestionIndex;
    return alphabets[index];
  }

  void _handleSpeechButton(QuizState quizState, String currentAlphabet) async {
    // Implement your speech recognition logic here
    final isCorrect = await _checkPronunciation(currentAlphabet);

    if (isCorrect) {
      quizState.incrementScore();
      _showResultDialog(context, quizState, isCorrect: true);
    } else {
      _showResultDialog(context, quizState, isCorrect: false);
    }
  }

  Future<bool> _checkPronunciation(String expected) async {
    print(
      !_speech.isAvailable
          ? 'Speech recognition not available'
          : 'Starting speech recognition...',
    );
    if (!_speech.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return false;
    }

    setState(() => _isListening = true);

    bool isCorrect = false;
    await _speech.listen(
      onResult: (result) {
        print(result);
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          setState(() {
            _lastWords = result.recognizedWords.toUpperCase();
            isCorrect = _lastWords.contains(expected);
          });
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
      localeId: 'id-ID',
      onSoundLevelChange: (level) {
        print('Sound level: $level');
      },
    );

    // Wait for speech recognition to complete
    await Future.delayed(const Duration(seconds: 5));

    setState(() => _isListening = false);
    _speech.stop();

    print('Speech recognition stopped. Result: $_lastWords');
    return isCorrect;
  }

  void _showResultDialog(
    BuildContext context,
    QuizState quizState, {
    required bool isCorrect,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? 'Correct!' : 'Try Again'),
        content: Text(
          isCorrect ? 'Great pronunciation!' : 'That didn\'t match. Try again.',
        ),
        actions: [
          if (isCorrect)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                quizState.nextQuestion();
                if (quizState.isLevelComplete) {
                  _showLevelCompleteDialog(context, quizState);
                }
              },
              child: const Text('Next'),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  void _showLevelCompleteDialog(BuildContext context, QuizState quizState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Text(
          'You completed Level ${quizState.currentLevel} '
          'with ${quizState.score}/10 correct!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              quizState.resetLevel();
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
