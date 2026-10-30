import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/letter.dart';
import '../models/practice_question.dart';
import '../services/practice_engine.dart';
import '../services/progress_service.dart';

/// Letter Practice Lab: a randomized quiz across the A–E question types.
class LetterPracticeScreen extends StatefulWidget {
  const LetterPracticeScreen({
    super.key,
    required this.allLetters,
    this.focusIds,
    this.onFinished,
  });

  final List<ArabicLetter> allLetters;
  final Set<String>? focusIds;
  final VoidCallback? onFinished;

  @override
  State<LetterPracticeScreen> createState() => _LetterPracticeScreenState();
}

class _LetterPracticeScreenState extends State<LetterPracticeScreen> {
  final _engine = PracticeEngine.instance;
  final _progress = QuranProgressService.instance;

  late List<PracticeQuestion> _questions;
  int _index = 0;
  String? _selected;
  bool _answered = false;
  int _score = 0;
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    _questions = _engine.buildLetterSession(
      widget.allLetters,
      focusIds: widget.focusIds,
      count: 10,
    );
  }

  PracticeQuestion? get _current =>
      _index < _questions.length ? _questions[_index] : null;

  Future<void> _answer(String option) async {
    if (_answered) return;
    final q = _current;
    if (q == null) return;
    final correct = q.isCorrect(option);
    setState(() {
      _selected = option;
      _answered = true;
      if (correct) {
        _score++;
      } else {
        _mistakes++;
      }
    });

    ArabicLetter? letter;
    for (final l in widget.allLetters) {
      if (l.id == q.letterId) {
        letter = l;
        break;
      }
    }
    final arabic = q.optionsAreArabic
        ? q.correctAnswer
        : (letter?.arabic ?? q.promptArabic);
    final kind = _kindFor(q.type);

    if (correct) {
      final weak = _progress.weakWords();
      final idx = weak.indexWhere((w) => w.arabic == arabic && w.kind == kind);
      if (idx >= 0) await _progress.recordCorrect(weak[idx]);
    } else {
      await _progress.recordMistake(
        arabic: arabic,
        reference: letter != null ? 'হরফ: ${letter.nameBn}' : q.explanationBn,
        kind: kind,
        parts: q.promptArabic.split(' + '),
      );
    }
  }

  String _kindFor(String type) {
    switch (type) {
      case 'harakat':
        return 'harakat';
      case 'makhraj':
      case 'voice':
        return 'makhraj';
      case 'join':
        return 'join';
      case 'letter':
      case 'audio':
      default:
        return 'letter';
    }
  }

  void _next() {
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
    });
  }

  void _restart() {
    setState(() {
      _questions = _engine.buildLetterSession(
        widget.allLetters,
        focusIds: widget.focusIds,
        count: 10,
      );
      _index = 0;
      _selected = null;
      _answered = false;
      _score = 0;
      _mistakes = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _current;
    return Scaffold(
      appBar: AppBar(
        title: const Text('প্র্যাকটিস ল্যাব'),
        actions: [
          if (q != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_index + 1}/${_questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: q == null ? _summary() : _questionView(q),
    );
  }

  Widget _questionView(PracticeQuestion q) {
    return Column(
      children: [
        ClipRRect(
          child: LinearProgressIndicator(
            value: (_index) / _questions.length,
            minHeight: 5,
            backgroundColor: Colors.white10,
            color: AppColors.accent,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              _typeBadge(q.type),
              const SizedBox(height: 18),
              Text(
                q.questionBn,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              if (q.promptArabic.isNotEmpty) _promptCard(q),
              const SizedBox(height: 24),
              ...q.options.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _option(q, o),
                ),
              ),
            ],
          ),
        ),
        if (_answered) _feedbackBar(q),
      ],
    );
  }

  Widget _typeBadge(String type) {
    final labels = {
      'letter': 'হরফ চেনা',
      'audio': 'শুনে চেনা',
      'harakat': 'হরকত',
      'makhraj': 'মাখরাজ',
      'join': 'হরফ জোড়া',
      'voice': 'নিজে পড়া',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        labels[type] ?? 'প্রশ্ন',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
        ),
      ),
    );
  }

  Widget _promptCard(PracticeQuestion q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        q.promptArabic,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: q.promptArabic.contains('+') ? 34 : 60,
          height: 1.6,
          fontFamily: 'Amiri',
          color: Colors.white,
        ),
        semanticsLabel: q.questionBn,
      ),
    );
  }

  Widget _option(PracticeQuestion q, String option) {
    final isCorrect = q.isCorrect(option);
    final isSelected = _selected == option;
    Color border = AppColors.border;
    Color? fill;
    if (_answered) {
      if (isCorrect) {
        border = AppColors.success;
        fill = AppColors.success.withValues(alpha: 0.14);
      } else if (isSelected) {
        border = AppColors.error;
        fill = AppColors.error.withValues(alpha: 0.14);
      }
    }
    final isArabic = q.optionsAreArabic;
    return Material(
      color: fill ?? AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _answered ? null : () => _answer(option),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: isArabic ? 30 : 15,
                    fontFamily: isArabic ? 'Amiri' : null,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_answered && isCorrect)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 22),
              if (_answered && isSelected && !isCorrect)
                const Icon(Icons.cancel_rounded, color: AppColors.error, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedbackBar(PracticeQuestion q) {
    final correct = _selected != null && q.isCorrect(_selected!);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.celebration_rounded : Icons.info_outline_rounded,
                color: correct ? AppColors.success : AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  q.explanationBn,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(_index + 1 >= _questions.length ? 'ফলাফল দেখো' : 'পরবর্তী'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    final total = _questions.length;
    final pct = total == 0 ? 0 : ((_score / total) * 100).round();
    final excellent = pct >= 80;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              excellent ? Icons.emoji_events_rounded : Icons.flag_rounded,
              size: 72,
              color: excellent ? AppColors.success : AppColors.accent,
            ),
            const SizedBox(height: 16),
            Text(
              excellent ? 'দুর্দান্ত!' : 'ভালো চেষ্টা!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'স্কোর: $_score / $total  ($pct%)',
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              _mistakes > 0
                  ? '$_mistakesটি ভুল হয়েছে — “দুর্বল শব্দ”-এ যোগ হয়েছে।'
                  : 'কোনো ভুল হয়নি!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white54),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('আবার অনুশীলন করো'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  widget.onFinished?.call();
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text('শেষ করো'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
