import 'package:flutter/material.dart';

class WordPracticeScreen extends StatelessWidget {
  const WordPracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('শব্দ অনুশীলন')),
      body: const Center(child: Text('Word Practice')),
    );
  }
}
