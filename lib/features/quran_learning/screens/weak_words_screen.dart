import 'package:flutter/material.dart';

class WeakWordsScreen extends StatelessWidget {
  const WeakWordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('আমার দুর্বল শব্দ')),
      body: const Center(child: Text('Weak Words')),
    );
  }
}
