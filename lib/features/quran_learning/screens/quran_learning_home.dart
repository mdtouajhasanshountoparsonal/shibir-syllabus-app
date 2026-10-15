import 'package:flutter/material.dart';

class QuranLearningHome extends StatelessWidget {
  const QuranLearningHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('কুরআন শেখা')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          Text('ডেটা লোড হচ্ছে...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
