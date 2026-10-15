import 'package:flutter/material.dart';


class LetterLessonScreen extends StatelessWidget {
  const LetterLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('হরফ পাঠ')),
      body: const Center(
        child: Text('Letter Lesson Screen', style: TextStyle(color: Colors.white54)),
      ),
    );
  }
}
