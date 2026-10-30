import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/quran_learning_repository.dart';
import '../models/level.dart';
import '../services/audio_service.dart';
import '../services/progress_service.dart';

/// Guided Quran reading practice: renders ayahs word-by-word so the learner
/// can touch each word, and records reading progress.
class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final _repo = QuranLearningRepository.instance;
  final _progress = QuranProgressService.instance;

  bool _loading = true;
  List<ReadingAyah> _ayahs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ayahs = await _repo.getAyahs();
    if (!mounted) return;
    setState(() {
      _ayahs = ayahs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('পড়ার অনুশীলন')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ayahs.isEmpty
              ? const Center(
                  child: Text('পাঠ্য ডেটা পাওয়া যায়নি।',
                      style: TextStyle(color: Colors.white54)),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                  children: [
                    const _IntroCard(),
                    const SizedBox(height: 16),
                    ..._ayahs.map((a) => _AyahBlock(ayah: a, progress: _progress)),
                  ],
                ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.lightbulb_rounded, color: AppColors.accent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'প্রতিটি শব্দ আলাদা করে চেনো। শব্দে চাপ দিলে অর্থ দেখতে পাবে।',
              style: TextStyle(fontSize: 12.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahBlock extends StatelessWidget {
  const _AyahBlock({required this.ayah, required this.progress});

  final ReadingAyah ayah;
  final QuranProgressService progress;

  @override
  Widget build(BuildContext context) {
    final done = progress.isLessonCompleted('read_${ayah.reference}');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ayah.reference,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => AudioService.instance.play(''),
                icon: const Icon(Icons.volume_up_rounded,
                    color: AppColors.accent),
                tooltip: 'তিলাওয়াত শোনো',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 6,
              runSpacing: 8,
              children: ayah.words
                  .map(
                    (w) => _WordChip(
                      word: w,
                      ayah: ayah,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            ayah.meaning,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await progress.markLessonCompleted('read_${ayah.reference}');
                await progress.setCurrentLesson(
                  'read_${ayah.reference}',
                  'পড়া: ${ayah.reference}',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('পড়া সম্পন্ন হিসেবে চিহ্নিত')),
                  );
                }
              },
              icon: Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                size: 16,
                color: done ? AppColors.success : null,
              ),
              label: Text(done ? 'পড়া হয়েছে' : 'পড়া সম্পন্ন'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, required this.ayah});

  final String word;
  final ReadingAyah ayah;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                word,
                style: const TextStyle(
                  fontSize: 44,
                  fontFamily: 'Amiri',
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ayah.meaning,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          word,
          style: const TextStyle(
            fontSize: 30,
            height: 1.6,
            fontFamily: 'Amiri',
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
