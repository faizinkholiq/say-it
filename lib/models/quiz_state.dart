import 'package:flutter/foundation.dart';

class QuizState with ChangeNotifier {
  int _currentLevel = 1;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLevelComplete = false;

  int get currentLevel => _currentLevel;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  bool get isLevelComplete => _isLevelComplete;

  List<String> getAlphabetsForLevel() {
    return List.generate(26, (index) => String.fromCharCode(65 + index));
  }

  void nextQuestion() {
    if (_currentQuestionIndex < 9) {
      _currentQuestionIndex++;
    } else {
      _isLevelComplete = true;
    }
    notifyListeners();
  }

  void resetLevel() {
    _currentQuestionIndex = 0;
    _score = 0;
    _isLevelComplete = false;
    notifyListeners();
  }

  void setLevel(int level) {
    _currentLevel = level;
    resetLevel();
    notifyListeners();
  }

  void incrementScore() {
    _score++;
    notifyListeners();
  }
}
