import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final quizState = Provider.of<QuizState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Alphabet Quiz')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Select Level', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 30),
            _buildLevelButton(context, quizState, 1),
            const SizedBox(height: 20),
            _buildLevelButton(context, quizState, 2),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelButton(
    BuildContext context,
    QuizState quizState,
    int level,
  ) {
    return ElevatedButton(
      onPressed: () {
        quizState.setLevel(level);
        Navigator.pushNamed(context, '/quiz');
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      ),
      child: Text('Level $level', style: const TextStyle(fontSize: 20)),
    );
  }
}
