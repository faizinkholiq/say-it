import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/quiz_state.dart';
import 'pages/home_page.dart';
import 'pages/quiz_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => QuizState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alphabet Pronunciation Quiz',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      routes: {'/quiz': (context) => const QuizPage()},
    );
  }
}
