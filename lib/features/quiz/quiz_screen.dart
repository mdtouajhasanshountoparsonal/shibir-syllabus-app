import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/content_manifest.dart';
import '../../data/models/quiz.dart';
import '../../data/repositories/content_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';

/// Lists available quizzes grouped by stage.
class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key, this.bundle});
  final ContentBundle? bundle;

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  ContentBundle? _bundle;

  @override
  void initState() {
    super.initState();
    if (widget.bundle != null) {
      _bundle = widget.bundle;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final bundle = await ContentRepository.instance.load();
    if (!mounted) return;
    setState(() => _bundle = bundle);
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    if (bundle == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final stageTitles = {
      for (final s in bundle.stages) s.id: s.title,
    };
    final grouped = <String, List<QuizQuestion>>{};
    for (final quiz in bundle.quizzes) {
      grouped.putIfAbsent(quiz.stage, () => []).add(quiz);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('কুইজ ও মূল্যায়ন')),
      body: grouped.isEmpty
          ? const EmptyState(
              icon: Icons.quiz_outlined,
              title: 'কোনো কুইজ নেই',
              message: 'GitHub-এর quizzes.json ফাইলে প্রশ্ন যোগ করলে এখানে দেখা যাবে।',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                const SectionHeader(
                  title: 'নিজস্ব মূল্যায়ন',
                  subtitle: 'অনুশীলন করে নিজের বোঝাপড়া যাচাই করো',
                ),
                const SizedBox(height: 12),
                ...grouped.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0x224DA3FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.quiz_rounded,
                              color: AppColors.info),
                        ),
                        title: Text(
                          stageTitles[entry.key] ?? 'সাধারণ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('${entry.value.length}টি প্রশ্ন'),
                        trailing:
                            const Icon(Icons.play_arrow_rounded,
                                color: AppColors.accent),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QuizPlayScreen(
                              title: stageTitles[entry.key] ?? 'কুইজ',
                              questions: entry.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Plays through a list of questions and shows the score.
class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({
    super.key,
    required this.title,
    required this.questions,
  });

  final String title;
  final List<QuizQuestion> questions;

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int _index = 0;
  final Map<int, int> _answers = {};
  bool _finished = false;

  QuizQuestion get _question => widget.questions[_index];
  int get _score {
    var s = 0;
    _answers.forEach((i, answer) {
      if (i < widget.questions.length &&
          widget.questions[i].correctIndex == answer) {
        s++;
      }
    });
    return s;
  }

  void _select(int optionIndex) {
    setState(() => _answers[_index] = optionIndex);
  }

  void _next() {
    if (_index < widget.questions.length - 1) {
      setState(() => _index++);
    } else {
      setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _finished ? _buildResult() : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    final selected = _answers[_index];
    final progress = (_index + 1) / widget.questions.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: Colors.white12,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 8),
        Text('প্রশ্ন ${_index + 1} / ${widget.questions.length}',
            style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
        const SizedBox(height: 20),
        Text(
          _question.question,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.5),
        ),
        const SizedBox(height: 18),
        ...List.generate(_question.options.length, (i) {
          final isSelected = selected == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => _select(i),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.seed.withValues(alpha: 0.18)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.accent : Colors.white38,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_question.options[i])),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: selected == null ? null : _next,
            child: Text(
              _index < widget.questions.length - 1 ? 'পরের প্রশ্ন' : 'ফলাফল দেখো',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final total = widget.questions.length;
    final ratio = total == 0 ? 0.0 : _score / total;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: ratio >= 0.6
                  ? const [Color(0xFF103A2A), Color(0xFF141A22)]
                  : const [Color(0xFF3A2410), Color(0xFF141A22)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: ratio >= 0.6
                  ? const Color(0x443DD68C)
                  : const Color(0x44F2B33D),
            ),
          ),
          child: Column(
            children: [
              Icon(
                ratio >= 0.6
                    ? Icons.emoji_events_rounded
                    : Icons.trending_up_rounded,
                size: 44,
                color: ratio >= 0.6 ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(height: 14),
              Text('$_score / $total',
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${(ratio * 100).round()}% সঠিক',
                  style: const TextStyle(color: Colors.white60)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'উত্তর পর্যালোচনা'),
        const SizedBox(height: 10),
        ...List.generate(total, (i) {
          final q = widget.questions[i];
          final answered = _answers[i];
          final correct = answered == q.correctIndex;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        correct
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: correct ? AppColors.success : AppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(q.question,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, height: 1.4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!correct && answered != null)
                    Text('তোমার উত্তর: ${q.options[answered]}',
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 12.5)),
                  Text('সঠিক উত্তর: ${q.options[q.correctIndex]}',
                      style: const TextStyle(
                          color: AppColors.success, fontSize: 12.5)),
                  if (q.explanation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(q.explanation,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12.5, height: 1.5)),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.done_rounded, size: 18),
            label: const Text('শেষ করো'),
          ),
        ),
      ],
    );
  }
}
