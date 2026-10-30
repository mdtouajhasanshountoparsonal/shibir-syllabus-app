import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/letter.dart';
import '../models/lesson.dart';
import '../services/audio_service.dart';
import '../services/progress_service.dart';
import 'letter_practice_screen.dart';
import 'reading_screen.dart';

/// Lesson overview: lists the letters of a lesson and opens each one.
class LetterLessonScreen extends StatelessWidget {
  const LetterLessonScreen({
    super.key,
    required this.lesson,
    required this.allLetters,
  });

  final Lesson lesson;
  final List<ArabicLetter> allLetters;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final l in allLetters) l.id: l};
    final items = lesson.letterIds
        .map((id) => byId[id])
        .whereType<ArabicLetter>()
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(lesson.titleBn)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
        children: [
          if (lesson.subtitleBn.isNotEmpty)
            Text(
              lesson.subtitleBn,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'Amiri',
              ),
            ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _emptyNote(context)
          else
            ...items.map(
              (letter) => _LetterRow(
                letter: letter,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LetterDetailScreen(
                      letter: letter,
                      allLetters: allLetters,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LetterPracticeScreen(
                        allLetters: allLetters,
                        focusIds: lesson.letterIds.toSet(),
                        onFinished: () => QuranProgressService.instance
                            .markLessonCompleted(lesson.id),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.school_rounded, size: 18),
                  label: const Text('প্র্যাকটিস ল্যাব শুরু করো'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _emptyNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'এই পাঠটি পড়ার ও তাজবিদ অনুশীলনের জন্য।',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'নিচের বোতাম থেকে সরাসরি কুরআন পড়ার অনুশীলন শুরু করো।',
            style: TextStyle(fontSize: 12.5, color: Colors.white60),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReadingScreen()),
            ),
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: const Text('পড়ার অনুশীলন করো'),
          ),
        ],
      ),
    );
  }
}

class _LetterRow extends StatelessWidget {
  const _LetterRow({required this.letter, required this.onTap});

  final ArabicLetter letter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Text(
                letter.arabic,
                style: const TextStyle(
                  fontSize: 40,
                  fontFamily: 'Amiri',
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      letter.nameBn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${letter.nameEn} · ${letter.makhraj}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 4,
                children: letter.forms
                    .map(
                      (f) => Text(
                        f,
                        style: const TextStyle(fontSize: 18, fontFamily: 'Amiri'),
                      ),
                    )
                    .toList(),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full, single-letter learning page.
class LetterDetailScreen extends StatefulWidget {
  const LetterDetailScreen({
    super.key,
    required this.letter,
    required this.allLetters,
  });

  final ArabicLetter letter;
  final List<ArabicLetter> allLetters;

  @override
  State<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends State<LetterDetailScreen> {
  final _progress = QuranProgressService.instance;

  @override
  void initState() {
    super.initState();
    _progress.setLastLetter(widget.letter.id);
  }

  ArabicLetter get letter => widget.letter;

  @override
  Widget build(BuildContext context) {
    final learned = _progress.isLetterLearned(letter.id);
    final byId = {for (final l in widget.allLetters) l.id: l};

    return Scaffold(
      appBar: AppBar(title: Text('হরফ: ${letter.nameBn}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 130),
        children: [
          _heroCard(),
          const SizedBox(height: 16),
          _InfoData(
            icon: Icons.record_voice_over_rounded,
            title: 'উচ্চারণস্থান (মাখরাজ)',
            value: letter.makhraj,
          ),
          const SizedBox(height: 12),
          _InfoData(
            icon: Icons.blur_on_rounded,
            title: 'বিন্দুর অবস্থান',
            value: letter.dotInfo,
          ),
          const SizedBox(height: 22),
          const Text(
            'হরফের আকৃতি (শুরু / মাঝ / শেষ / আলাদা)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _formsRow(),
          const SizedBox(height: 22),
          const Text(
            'হরকতসহ উচ্চারণ',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _harakatGrid(),
          if (letter.similarLetters.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text(
              'মিলিয়ে পড়ো (সাদৃশ্য হরফ)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: letter.similarLetters
                  .map((id) => byId[id])
                  .whereType<ArabicLetter>()
                  .map(
                    (l) => ActionChip(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      label: Text(
                        l.arabic,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => LetterDetailScreen(
                            letter: l,
                            allLetters: widget.allLetters,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: learned
                      ? null
                      : () async {
                          await _progress.markLetterLearned(letter.id);
                          if (mounted) setState(() {});
                        },
                  icon: Icon(
                    learned
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: Text(learned ? 'শেখা হয়েছে' : 'শিখেছি'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await _progress.markLetterLearned(letter.id);
                    if (!context.mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LetterPracticeScreen(
                          allLetters: widget.allLetters,
                          focusIds: {letter.id},
                        ),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.school_rounded, size: 18),
                  label: const Text('অনুশীলন'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF20304A), Color(0xFF141A22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            letter.arabic,
            style: const TextStyle(
              fontSize: 96,
              height: 1.1,
              fontFamily: 'Amiri',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            letter.nameBn,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            letter.nameEn,
            style: const TextStyle(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () => AudioService.instance.play(
                  letter.pronunciationUrl,
                ),
                icon: const Icon(Icons.volume_up_rounded),
                tooltip: 'উচ্চারণ শোনো',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formsRow() {
    final labels = letter.formLabels.isNotEmpty
        ? letter.formLabels
        : const ['শুরু', 'মাঝে', 'শেষ', 'আলাদা'];
    return Row(
      children: [
        for (var i = 0; i < letter.forms.length; i++)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    letter.forms[i],
                    style: const TextStyle(
                      fontSize: 30,
                      fontFamily: 'Amiri',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    i < labels.length ? labels[i] : '',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _harakatGrid() {
    final entries = [
      ('ফাতহা', letter.fatha),
      ('কাসরা', letter.kasra),
      ('দাম্মা', letter.damma),
      ('সুকুন', letter.sukun),
      ('শাদ্দাহ', letter.shadda),
      ('তানভীন', letter.harakat['tanween'] ?? letter.arabic),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: entries
          .map(
            (e) => Container(
              width: 84,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    e.$2,
                    style: const TextStyle(
                      fontSize: 28,
                      fontFamily: 'Amiri',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.$1,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InfoData extends StatelessWidget {
  const _InfoData({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
