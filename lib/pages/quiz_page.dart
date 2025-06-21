import 'dart:async';

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
  bool _hasSpeechError = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Status: $status'),
        onError: (error) {
          setState(() => _hasSpeechError = true);
          print('Error: $error');
        },
      );
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Speech recognition not available")),
        );
      }
    } catch (e) {
      print("Speech init error: $e");
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
                _buildAlphabetDisplay(currentAlphabet),
                const SizedBox(height: 50),
                _buildSpeechButton(context, quizState, currentAlphabet),
                if (_hasSpeechError)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'Recognition failed. Try again!',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
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
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 10),
                Text('Listening...'),
              ],
            )
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
    setState(() {
      _isListening = true;
      _lastWords = '';
      _hasSpeechError = false;
    });

    try {
      final isCorrect = await _checkPronunciation(currentAlphabet);

      if (isCorrect) {
        quizState.incrementScore();
        _showResultDialog(context, quizState, isCorrect: true);
      } else {
        _showResultDialog(
          context,
          quizState,
          isCorrect: false,
          spokenText: _lastWords,
        );
      }
    } catch (e) {
      setState(() => _hasSpeechError = true);
    } finally {
      setState(() => _isListening = false);
    }
  }

  Future<bool> _checkPronunciation(String expectedLetter) async {
    if (!_speech.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return false;
    }

    final completer = Completer<bool>();
    String recognizedText = "";

    await _speech.listen(
      onResult: (result) {
        print('Speech result: ${result.recognizedWords}');
        if (result.finalResult) {
          recognizedText = result.recognizedWords.toUpperCase();
          setState(() => _lastWords = recognizedText);

          final expected = expectedLetter.toUpperCase();
          final isMatch =
              recognizedText.contains(expected) ||
              _checkPhoneticMatch(recognizedText, expected);
          completer.complete(isMatch);
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
      localeId: 'id-ID',
      onSoundLevelChange: (level) {},
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );

    return await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => false,
    );
  }

  void _showResultDialog(
    BuildContext context,
    QuizState quizState, {
    required bool isCorrect,
    String spokenText = '',
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? 'Correct!' : 'Try Again'),
        content: Text(
          isCorrect
              ? 'Great pronunciation!'
              : 'You said "$spokenText". Try pronouncing "${_getCurrentAlphabet()}" again.',
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

  bool _checkPhoneticMatch(String spoken, String letter) {
    // Map letters to their phonetic pronunciations
    final phoneticMap = {
      'A': ['ey', 'ah'],
      'B': ['bee', 'be'],
      'C': ['see', 'ce'],
      'D': ['dee', 'de'],
      'E': ['ee', 'eh'],
      'F': ['ef'],
      'G': ['jee', 'ge'],
      'H': ['eych', 'ha'],
      'I': ['ai', 'ee'],
      'J': ['jay', 'je'],
      'K': ['kay', 'ka'],
      'L': ['el'],
      'M': ['em'],
      'N': ['en'],
      'O': ['oh', 'ow'],
      'P': ['pee', 'pe'],
      'Q': ['kyoo', 'kew'],
      'R': ['ar', 'er'],
      'S': ['es'],
      'T': ['tee', 'te'],
      'U': ['yoo', 'you'],
      'V': ['vee', 've'],
      'W': ['double yoo', 'dabelyu'],
      'X': ['ex', 'eks'],
      'Y': ['why', 'wai'],
      'Z': ['zee', 'zed'],
    };

    final phonetics = phoneticMap[letter] ?? [];
    return phonetics.any((ph) => spoken.toLowerCase().contains(ph));
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
