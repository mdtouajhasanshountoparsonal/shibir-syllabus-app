import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/practice_question.dart';

/// A reusable, self-contained quiz runner used by the word-practice and
/// revision screens. The caller supplies [questions] and an [onAnswer]
/// callback to persist results.
class PracticeRunner extends StatefulWidget {
  const PracticeRunner({
    super.key,
    required this.questions,
    required this.onAnswer,
    this.onFinished,
    this.emptyLabel = 'এখন কোনো অনুশীলন নেই।',
  });

  final List<PracticeQuestion> questions;
  final void Function(PracticeQuestion question, bool correct) onAnswer;
  final VoidCallback? onFinished;
  final String emptyLabel;

  @override
  State<PracticeRunner> createState() => _PracticeRunnerState();
}

class _PracticeRunnerState extends State<PracticeRunner> {
  int _index = 0;
  String? _selected;
  bool _answered = false;
  int _score = 0;
  int _mistakes = 0;

  PracticeQuestion? get _current =>
      _index < widget.questions.length ? widget.questions[_index] : null;

  void _answer(String option) {
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
    widget.onAnswer(q, correct);
  }

  void _next() => setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) return _empty();
    final q = _current;
    return q == null ? _summary() : _questionView(q);
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            widget.emptyLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.white70),
          ),
        ),
      );

  Widget _questionView(PracticeQuestion q) {
    return Column(
      children: [
        ClipRRect(
          child: LinearProgressIndicator(
            value: _index / widget.questions.length,
            minHeight: 5,
            backgroundColor: Colors.white10,
            color: AppColors.accent,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text(
                '${_index + 1} / ${widget.questions.length}',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 14),
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
          fontSize: q.optionsAreArabic ? 30 : 34,
          height: 1.8,
          fontFamily: 'Amiri',
          color: Colors.white,
        ),
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
          child: Text(
            option,
            style: TextStyle(
              fontSize: q.optionsAreArabic ? 30 : 15,
              fontFamily: q.optionsAreArabic ? 'Amiri' : null,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _feedbackBar(PracticeQuestion q) {
    final correct = q.isCorrect(_selected ?? '');
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  correct
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
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
                child: Text(
                  _index + 1 >= widget.questions.length ? 'ফলাফল' : 'পরবর্তী',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary() {
    final total = widget.questions.length;
    final pct = total == 0 ? 0 : ((_score / total) * 100).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              pct >= 80 ? Icons.emoji_events_rounded : Icons.flag_rounded,
              size: 68,
              color: pct >= 80 ? AppColors.success : AppColors.accent,
            ),
            const SizedBox(height: 16),
            Text(
              'স্কোর: $_score / $total  ($pct%)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _mistakes > 0
                  ? '$_mistakesটি ভুল — “দুর্বল শব্দ”-এ যোগ হয়েছে।'
                  : 'কোনো ভুল হয়নি!',
              style: const TextStyle(fontSize: 13, color: Colors.white54),
            ),
            const SizedBox(height: 28),
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
