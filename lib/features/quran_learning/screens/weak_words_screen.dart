import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/quran_learning_repository.dart';
import '../models/level.dart';
import '../models/weak_word.dart';
import '../services/practice_engine.dart';
import '../services/progress_service.dart';
import '../widgets/practice_runner.dart';

/// "My Weak Words" — the personal mistake list with spaced revision.
class WeakWordsScreen extends StatefulWidget {
  const WeakWordsScreen({super.key});

  @override
  State<WeakWordsScreen> createState() => _WeakWordsScreenState();
}

class _WeakWordsScreenState extends State<WeakWordsScreen> {
  final _progress = QuranProgressService.instance;
  final _repo = QuranLearningRepository.instance;

  List<PracticeWord> _words = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final words = await _repo.getWords();
    if (!mounted) return;
    setState(() {
      _words = words;
      _loading = false;
    });
  }

  Future<void> _practice(WeakWord word) async {
    final questions =
        PracticeEngine.instance.buildRevisionSession([word], _words);
    if (questions.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('পুনরায় অনুশীলন')),
          body: PracticeRunner(
            questions: questions,
            onAnswer: (q, correct) async {
              if (correct) {
                await _progress.recordCorrect(word);
              } else {
                await _progress.recordMistake(
                  arabic: word.arabic,
                  reference: word.reference,
                  kind: word.kind,
                  parts: word.splitParts,
                );
              }
            },
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = _progress.weakWords();
    return Scaffold(
      appBar: AppBar(title: const Text('আমার দুর্বল শব্দ')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? _empty()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                  children: [
                    const SectionHeader(
                      title: 'ভুল হওয়া পদগুলো',
                      subtitle: 'যেগুলো বারবার ভুল হয় সেগুলো এখানে জমা হয়',
                    ),
                    const SizedBox(height: 14),
                    ...list.map((w) => _weakCard(w)),
                  ],
                ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.verified_rounded, size: 64, color: AppColors.success),
              SizedBox(height: 16),
              Text(
                'দুর্বল শব্দ নেই!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'প্র্যাকটিস ল্যাবে ভুল করলে শব্দগুলো এখানে জমা হবে।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white54),
              ),
            ],
          ),
        ),
      );

  Widget _weakCard(WeakWord w) {
    final due = !w.nextReview.isAfter(DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  w.arabic,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 30,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  w.kindLabelBn,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            w.reference,
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _chip('ভুল: ${w.wrongCount}', AppColors.error),
              const SizedBox(width: 8),
              _chip('সঠিক ধারা: ${w.correctStreak}', AppColors.success),
              const Spacer(),
              Text(
                w.mastered
                    ? 'মুখস্থ ✓'
                    : (due ? 'এখন রিভিশন' : 'পরে'),
                style: TextStyle(
                  fontSize: 11,
                  color: w.mastered
                      ? AppColors.success
                      : (due ? AppColors.accent : Colors.white54),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _progress.removeWeakWord(w.id);
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('মুছে ফেলো'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _practice(w),
                  icon: const Icon(Icons.school_rounded, size: 16),
                  label: const Text('অনুশীলন'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      );
}
