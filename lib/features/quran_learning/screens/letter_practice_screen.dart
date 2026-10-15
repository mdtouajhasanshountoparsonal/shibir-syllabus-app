import 'package:flutter/material.dart';

class LetterPracticeScreen extends StatelessWidget {
  const LetterPracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('হরফ অনুশীলন')),
      body: const Center(child: Text('Letter Practice')),
    );
  }
}
