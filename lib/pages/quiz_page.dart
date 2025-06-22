import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_state.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';
  bool _hasSpeechError = false;
  late List<String> _sentences;
  late List<String> _selectedSentences;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _initializeSentences();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _initializeSentences() {
    _sentences = [
      'Saya makan',
      'Jalan-jalan',
      'Kita bermain',
      'Dia berlari',
      'Dia melompat',
      'Mereka duduk',
      'Kita membaca',
      'Saya tidur',
      'Kamu berjalan',
      'Mereka berbicara',
      'Saya berenang',
      'Kamu menyanyi',
      'Kita menari',
      'Dia menulis',
      'Dia membaca',
      'Mereka memasak',
      'Kita belajar',
      'Saya bekerja',
      'Kamu berlari',
      'Mereka tertawa',
    ];
    _selectedSentences = [];
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
          const SnackBar(content: Text("Pengenalan suara tidak tersedia")),
        );
      }
    } catch (e) {
      print("Speech init error: $e");
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<QuizState>(
      builder: (context, quizState, child) {
        if (quizState.currentLevel == 2 && _selectedSentences.isEmpty) {
          _selectedSentences = _getRandomSentences();
        }

        final currentContent = _getCurrentContent(quizState);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Level ${quizState.currentLevel} - Pertanyaan ${quizState.currentQuestionIndex + 1}/10',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            backgroundColor: isDarkMode
                ? Color.fromARGB(255, 52, 73, 94)
                : Colors.white,
            elevation: 0,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [
                        Color.fromARGB(255, 52, 73, 94),
                        Color.fromARGB(255, 52, 73, 94),
                      ]
                    : [Colors.white, Colors.teal.shade50],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      quizState.currentLevel == 2
                          ? 'Ucapkan kalimat ini:'
                          : 'Ucapkan huruf ini 3 kali:',
                      style: TextStyle(
                        fontSize: 20,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildContentDisplay(
                        quizState.currentLevel,
                        currentContent,
                        isDarkMode,
                      ),
                    ),
                    const SizedBox(height: 50),
                    _buildSpeechButton(
                      context,
                      quizState,
                      currentContent,
                      isDarkMode,
                    ),
                    const SizedBox(height: 20),
                    if (_hasSpeechError)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          'Pengenalan gagal. Coba lagi!',
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> _getRandomSentences() {
    final random = Random();
    List<String> shuffled = List.from(_sentences);
    shuffled.shuffle(random);
    return shuffled.take(10).toList();
  }

  Widget _buildContentDisplay(int level, String content, bool isDarkMode) {
    return Container(
      child: Text(
        content,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: level == 2 ? 45 : 80,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.teal,
        ),
      ),
    );
  }

  Widget _buildSpeechButton(
    BuildContext context,
    QuizState quizState,
    String currentContent,
    bool isDarkMode,
  ) {
    return ElevatedButton(
      onPressed: () => _handleSpeechButton(quizState, currentContent),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        backgroundColor: isDarkMode
            ? Color.fromARGB(255, 26, 188, 156)
            : Colors.teal.shade400,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        shadowColor: isDarkMode
            ? Colors.teal.shade200.withOpacity(0.5)
            : Colors.teal.shade200,
      ),
      child: _isListening
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Mendengarkan...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Text(
              'Mulai Berbicara',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  String _getCurrentContent(QuizState quizState) {
    if (quizState.currentLevel == 2) {
      return _selectedSentences[quizState.currentQuestionIndex];
    } else {
      final alphabets = quizState.getAlphabets();
      return alphabets[quizState.currentQuestionIndex];
    }
  }

  void _handleSpeechButton(QuizState quizState, String currentContent) async {
    setState(() {
      _isListening = true;
      _lastWords = '';
      _hasSpeechError = false;
    });

    _animationController.repeat(reverse: true);

    try {
      final isCorrect = await _checkPronunciation(
        quizState.currentLevel,
        currentContent,
      );

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
      _animationController.stop();
      _animationController.value = 1.0;
      setState(() => _isListening = false);
    }
  }

  Future<bool> _checkPronunciation(int level, String expectedLetter) async {
    if (!_speech.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengenalan suara tidak tersedia')),
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
          final isMatch = level == 2
              ? recognizedText.contains(expected)
              : recognizedText.contains(expected) ||
                    _checkPhoneticMatch(recognizedText, expected);
          completer.complete(isMatch);
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
      localeId: 'id-ID',
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );

    return await completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () => false,
    );
  }

  void _showResultDialog(
    BuildContext context,
    QuizState quizState, {
    required bool isCorrect,
    String spokenText = '',
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final content = _getCurrentContent(quizState);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: isCorrect
                    ? Icon(
                        Icons.check_circle,
                        color: Color.fromARGB(255, 26, 188, 156),
                        size: 80,
                        key: ValueKey('correct'),
                      )
                    : Icon(
                        Icons.error_outline,
                        color: Colors.orange.shade400,
                        size: 80,
                        key: ValueKey('incorrect'),
                      ),
              ),
              const SizedBox(height: 20),

              ScaleTransition(
                scale: CurvedAnimation(
                  parent: ModalRoute.of(context)!.animation!,
                  curve: Curves.elasticOut,
                ),
                child: Text(
                  isCorrect ? 'Benar!' : 'Coba Lagi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isCorrect
                        ? Color.fromARGB(255, 26, 188, 156)
                        : Colors.orange.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              FadeTransition(
                opacity: CurvedAnimation(
                  parent: ModalRoute.of(context)!.animation!,
                  curve: Curves.easeIn,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      Text(
                        isCorrect
                            ? 'Pengucapan Anda bagus!'
                            : 'Anda mengucapkan:',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '"$spokenText"',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba ucapkan:',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.blueGrey.shade800
                                : Colors.teal.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '"$content"',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.teal.shade900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCorrect)
                    ElevatedButton.icon(
                      icon: Icon(Icons.arrow_forward, size: 20),
                      label: Text('Lanjut'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 26, 188, 156),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        quizState.nextQuestion();
                        if (quizState.isLevelComplete) {
                          _showLevelCompleteDialog(context, quizState);
                          _selectedSentences = [];
                        }
                      },
                    )
                  else
                    ElevatedButton.icon(
                      icon: Icon(Icons.replay, size: 20),
                      label: Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLevelCompleteDialog(BuildContext context, QuizState quizState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final score = quizState.score;
    final message = score >= 8
        ? 'Luar biasa!'
        : score >= 5
        ? 'Bagus!'
        : 'Tetap semangat!';
    final icon = score >= 8
        ? Icons.star
        : score >= 5
        ? Icons.thumb_up
        : Icons.emoji_objects;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: ModalRoute.of(context)!.animation!,
                  curve: Curves.elasticOut,
                ),
                child: Icon(
                  icon,
                  size: 80,
                  color: Color.fromARGB(255, 26, 188, 156),
                ),
              ),
              const SizedBox(height: 20),

              FadeTransition(
                opacity: ModalRoute.of(context)!.animation!,
                child: Text(
                  'Selamat!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 26, 188, 156),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.blueGrey.shade800
                      : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  'Skor: $score/10',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.teal.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Anda menyelesaikan Level ${quizState.currentLevel}',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              // Performance message with animation
              SlideTransition(
                position: Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero)
                    .animate(
                      CurvedAnimation(
                        parent: ModalRoute.of(context)!.animation!,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.amber.shade200
                        : Colors.teal.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                icon: Icon(Icons.home, size: 20),
                label: Text('Kembali ke Beranda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 26, 188, 156),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  elevation: 5,
                ),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  quizState.resetLevel();
                  _selectedSentences = [];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _checkPhoneticMatch(String spoken, String letter) {
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
}
