import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/quran_learning_repository.dart';
import '../models/letter.dart';
import '../models/lesson.dart';
import '../models/level.dart';
import '../services/progress_service.dart';
import 'letter_lesson_screen.dart';
import 'letter_practice_screen.dart';
import 'reading_screen.dart';
import 'revision_screen.dart';
import 'weak_words_screen.dart';
import 'word_practice_screen.dart';

class QuranLearningHome extends StatefulWidget {
  const QuranLearningHome({super.key});

  @override
  State<QuranLearningHome> createState() => _QuranLearningHomeState();
}

class _QuranLearningHomeState extends State<QuranLearningHome> {
  final _repo = QuranLearningRepository.instance;
  final _progress = QuranProgressService.instance;

  bool _loading = true;
  String? _error;
  List<ArabicLetter> _letters = const [];
  List<LearningLevel> _levels = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getLetters(),
        _repo.getLevels(),
      ]);
      if (!mounted) return;
      setState(() {
        _letters = results[0] as List<ArabicLetter>;
        _levels = results[1] as List<LearningLevel>;
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'ডেটা লোড করা যায়নি। আবার চেষ্টা করো।';
        _loading = false;
      });
    }
  }

  Future<void> _openLesson(Lesson lesson) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LetterLessonScreen(
          lesson: lesson,
          allLetters: _letters,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openLetter(ArabicLetter letter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LetterDetailScreen(
          letter: letter,
          allLetters: _letters,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'কুরআন শেখা',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView()
                : _contentView(),
      ),
    );
  }

  Widget _errorView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.white38),
        const SizedBox(height: 16),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('আবার চেষ্টা করো'),
          ),
        ),
      ],
    );
  }

  Widget _contentView() {
    final progress = _progress.load(totalLetters: _letters.length);
    final dueCount = _progress.dueWeakWords().length;
    final weakCount = progress.weakWords.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: [
        _DashboardCard(
          progress: progress,
          onContinue: _continueLesson(progress),
        ),
        const SizedBox(height: 18),
        _QuickActions(
          weakCount: weakCount,
          dueCount: dueCount,
          onPractice: () => _openPractice(null),
          onWords: () => _open(const WordPracticeScreen()),
          onWeak: () => _open(
            WeakWordsScreen(),
          ),
          onRevision: () => _open(const QuranRevisionScreen()),
          onReading: () => _open(const ReadingScreen()),
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: 'ধাপে ধাপে কোর্স (লেভেল ১–৫)',
          subtitle: 'বেসিক থেকে সম্পূর্ণ কুরআন পড়া পর্যন্ত',
        ),
        const SizedBox(height: 12),
        ..._levels.map(
          (level) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _LevelCard(
              level: level,
              letters: _letters,
              progress: _progress,
              onLessonTap: _openLesson,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SectionHeader(
          title: 'সব আরবি হরফ',
          subtitle: '${bnNumber(_letters.length)}টি হরফ — যেকোনোটি চাপো',
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 96,
          ),
          itemCount: _letters.length,
          itemBuilder: (context, index) => _LetterTile(
            letter: _letters[index],
            learned: _progress.isLetterLearned(_letters[index].id),
            onTap: () => _openLetter(_letters[index]),
          ),
        ),
      ],
    );
  }

  VoidCallback? _continueLesson(dynamic progress) {
    if (_levels.isEmpty) return null;
    // Prefer the stored current lesson; otherwise the very first lesson.
    for (final level in _levels) {
      for (final lesson in level.lessons) {
        if (lesson.id == _progress.currentLessonId) {
          return () => _openLesson(lesson);
        }
      }
    }
    final first = _levels.first.lessons.isNotEmpty
        ? _levels.first.lessons.first
        : null;
    if (first == null) return null;
    return () => _openLesson(first);
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  void _openPractice(String? letterId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LetterPracticeScreen(
          allLetters: _letters,
          focusIds: letterId == null ? null : {letterId},
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.progress, this.onContinue});

  final dynamic progress;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final pct = ((progress.overallProgress as double) * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B2433), Color(0xFF141A22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 74,
                      height: 74,
                      child: CircularProgressIndicator(
                        value: progress.overallProgress as double,
                        strokeWidth: 7,
                        backgroundColor: Colors.white10,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'আপনার অগ্রগতি',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bnNumber(progress.learnedCount as int)} / '
                      '${bnNumber(progress.totalLetters as int)} হরফ শেখা হয়েছে',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.play_lesson_rounded,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  (progress.currentLessonTitle as String).isEmpty
                      ? 'আজকের পাঠ: হরফ ১–৭ দিয়ে শুরু করো'
                      : 'শেষ পাঠ: ${progress.currentLessonTitle}',
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('শেখা চালিয়ে যাও'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.weakCount,
    required this.dueCount,
    required this.onPractice,
    required this.onWords,
    required this.onWeak,
    required this.onRevision,
    required this.onReading,
  });

  final int weakCount;
  final int dueCount;
  final VoidCallback onPractice;
  final VoidCallback onWords;
  final VoidCallback onWeak;
  final VoidCallback onRevision;
  final VoidCallback onReading;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _ActionTile(
          icon: Icons.school_rounded,
          label: 'প্র্যাকটিস ল্যাব',
          color: AppColors.accent,
          onTap: onPractice,
        ),
        _ActionTile(
          icon: Icons.merge_type_rounded,
          label: 'শব্দ তৈরি ও পড়া',
          color: AppColors.purple,
          onTap: onWords,
        ),
        _ActionTile(
          icon: Icons.bookmark_rounded,
          label: 'দুর্বল শব্দ',
          trailing: weakCount > 0 ? bnNumber(weakCount) : null,
          color: AppColors.error,
          onTap: onWeak,
        ),
        _ActionTile(
          icon: Icons.replay_rounded,
          label: 'রিভিশন',
          trailing: dueCount > 0 ? bnNumber(dueCount) : null,
          color: AppColors.success,
          onTap: onRevision,
        ),
        _ActionTile(
          icon: Icons.menu_book_rounded,
          label: 'পড়ার অনুশীলন',
          color: Colors.blueAccent,
          onTap: onReading,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trailing!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.letters,
    required this.progress,
    required this.onLessonTap,
  });

  final LearningLevel level;
  final List<ArabicLetter> letters;
  final QuranProgressService progress;
  final void Function(Lesson) onLessonTap;

  Color get _color => level.colorValue == 0
      ? AppColors.accent
      : Color(level.colorValue).withValues(alpha: 1);

  @override
  Widget build(BuildContext context) {
    final completed = level.lessons
        .where((l) => progress.isLessonCompleted(l.id))
        .length;
    final ratio =
        level.lessons.isEmpty ? 0.0 : completed / level.lessons.length;
    final byId = {for (final l in letters) l.id: l};

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              bnNumber(level.order),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _color,
                fontSize: 16,
              ),
            ),
          ),
          title: Text(
            level.titleBn,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.subtitleBn,
                  style: const TextStyle(fontSize: 11.5, color: Colors.white54),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: Colors.white10,
                    color: _color,
                  ),
                ),
              ],
            ),
          ),
          children: [
            if (level.goals.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'এই লেভেলে যা শিখবে:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...level.goals.map(
                      (g) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                size: 14, color: _color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                g,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white60,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ...level.lessons.map((lesson) {
              final done = progress.isLessonCompleted(lesson.id);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onLessonTap(lesson),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          done
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 20,
                          color: done ? AppColors.success : Colors.white30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.titleBn,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                              if (lesson.subtitleBn.isNotEmpty)
                                Text(
                                  lesson.subtitleBn,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white54,
                                    fontFamily: 'Amiri',
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (lesson.letterIds.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              lesson.letterIds
                                  .map((id) => byId[id]?.arabic ?? '')
                                  .join(' '),
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.white38, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.letter,
    required this.learned,
    required this.onTap,
  });

  final ArabicLetter letter;
  final bool learned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: learned
                  ? AppColors.success.withValues(alpha: 0.6)
                  : AppColors.border,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      letter.arabic,
                      style: const TextStyle(
                        fontSize: 30,
                        fontFamily: 'Amiri',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      letter.nameBn,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              if (learned)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
