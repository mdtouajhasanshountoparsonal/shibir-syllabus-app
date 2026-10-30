import 'package:flutter/material.dart';

import '../data/quran_learning_repository.dart';
import '../models/practice_question.dart';
import '../services/practice_engine.dart';
import '../services/progress_service.dart';
import '../widgets/practice_runner.dart';

/// Practice joining letter parts into complete words.
class WordPracticeScreen extends StatefulWidget {
  const WordPracticeScreen({super.key});

  @override
  State<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends State<WordPracticeScreen> {
  final _repo = QuranLearningRepository.instance;
  final _progress = QuranProgressService.instance;

  List<PracticeQuestion>? _questions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final words = await _repo.getWords();
    if (!mounted) return;
    setState(() {
      _questions = PracticeEngine.instance.buildWordSession(words);
    });
  }

  Future<void> _onAnswer(PracticeQuestion q, bool correct) async {
    if (correct) {
      final weak = _progress.weakWords();
      final idx = weak.indexWhere((w) => w.arabic == q.correctAnswer);
      if (idx >= 0) await _progress.recordCorrect(weak[idx]);
    } else {
      await _progress.recordMistake(
        arabic: q.correctAnswer,
        reference: q.explanationBn,
        kind: 'join',
        parts: q.promptArabic.split(' + '),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions;
    return Scaffold(
      appBar: AppBar(title: const Text('শব্দ তৈরি ও পড়া')),
      body: q == null
          ? const Center(child: CircularProgressIndicator())
          : PracticeRunner(
              questions: q,
              onAnswer: _onAnswer,
              emptyLabel: 'শব্দ ডেটা পাওয়া যায়নি।',
            ),
    );
  }
}
