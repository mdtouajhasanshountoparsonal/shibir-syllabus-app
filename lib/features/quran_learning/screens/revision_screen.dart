import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/quran_learning_repository.dart';
import '../models/practice_question.dart';
import '../models/weak_word.dart';
import '../services/practice_engine.dart';
import '../services/progress_service.dart';
import '../widgets/practice_runner.dart';

/// Spaced-revision session for words that are due for review.
class QuranRevisionScreen extends StatefulWidget {
  const QuranRevisionScreen({super.key});

  @override
  State<QuranRevisionScreen> createState() => _QuranRevisionScreenState();
}

class _QuranRevisionScreenState extends State<QuranRevisionScreen> {
  final _progress = QuranProgressService.instance;
  final _repo = QuranLearningRepository.instance;

  List<PracticeQuestion>? _questions;
  List<WeakWord> _due = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool all = false}) async {
    final words = await _repo.getWords();
    if (!mounted) return;
    final due = all ? _progress.weakWords() : _progress.dueWeakWords();
    final questions = PracticeEngine.instance.buildRevisionSession(due, words);
    setState(() {
      _due = due;
      _questions = questions;
      _loading = false;
    });
  }

  Future<void> _onAnswer(PracticeQuestion q, bool correct) async {
    WeakWord? match;
    for (final w in _due) {
      if (q.id == 'rev_${w.id}') {
        match = w;
        break;
      }
    }
    if (match == null) return;
    if (correct) {
      await _progress.recordCorrect(match);
    } else {
      await _progress.recordMistake(
        arabic: match.arabic,
        reference: match.reference,
        kind: match.kind,
        parts: match.splitParts,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('রিভিশন')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_questions == null || _questions!.isEmpty)
              ? _empty()
              : PracticeRunner(
                  questions: _questions!,
                  onAnswer: _onAnswer,
                  emptyLabel: 'এখন রিভিশনের কিছু নেই।',
                ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.task_alt_rounded,
                  size: 64, color: AppColors.success),
              const SizedBox(height: 16),
              const Text(
                'আজকের রিভিশন শেষ!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'পরের রিভিশন সময়মতো এখানে এসে জমা হবে।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white54),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _load(all: true),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('সব দুর্বল শব্দ রিভিশন করো'),
              ),
            ],
          ),
        ),
      );
}
