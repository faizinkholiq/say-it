import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_state.dart';
import '../models/theme_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final quizState = Provider.of<QuizState>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
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
            child: Column(
              children: [
                Text(
                  'Say It!',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 26, 188, 156),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Silahkan pilih level',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: screenWidth * 0.65,
                  child: Column(
                    children: [
                      _buildLevelCard(
                        context,
                        quizState,
                        1,
                        'Alfabet dasar',
                        isDarkMode,
                      ),
                      const SizedBox(height: 20),
                      _buildLevelCard(
                        context,
                        quizState,
                        2,
                        'Kalimat sederhana',
                        isDarkMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                IconButton(
                  icon: Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    size: 30,
                    color: isDarkMode
                        ? Colors.amber
                        : Color.fromARGB(255, 135, 141, 146),
                  ),
                  onPressed: () {
                    final themeProvider = Provider.of<ThemeNotifier>(
                      context,
                      listen: false,
                    );
                    themeProvider.toggleTheme();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    QuizState quizState,
    int level,
    String subtitle,
    bool isDarkMode,
  ) {
    return InkWell(
      onTap: () {
        quizState.setLevel(level);
        Navigator.pushNamed(context, '/quiz');
      },
      borderRadius: BorderRadius.circular(20),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: isDarkMode ? Color.fromARGB(255, 44, 62, 80) : Colors.white,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(25, 18, 20, 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
