import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/quiz_page.dart';
import 'pages/home_page.dart';
import 'models/quiz_state.dart';
import 'models/theme_state.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => QuizState()),
        ChangeNotifierProvider(create: (context) => ThemeNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'Say It!',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: Colors.purple,
          secondary: Colors.blue,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: const Color.fromARGB(255, 40, 67, 115),
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      themeMode: themeNotifier.themeMode,
      home: const HomePage(),
      routes: {'/quiz': (context) => const QuizPage()},
    );
  }
}
