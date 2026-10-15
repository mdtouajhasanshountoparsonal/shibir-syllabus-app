import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/book.dart';
import '../../data/models/enums.dart';
import '../../data/models/memorization.dart';
import '../../data/models/syllabus.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../shared/widgets/status_pill.dart';
import '../library/book_detail_screen.dart';
import '../memorization/memorization_screen.dart';
import '../quiz/quiz_screen.dart';
import 'stage_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.item, this.stageId = ''});
  final SyllabusItem item;
  final String stageId;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _progress = ProgressRepository.instance;
  late StudyStatus _status;
  Book? _book;
  MemorizationItem? _memo;
  int _stageQuizCount = 0;

  @override
  void initState() {
    super.initState();
    _status = _progress.get(widget.item.id).status;
    _resolveBook();
  }

  Future<void> _resolveBook() async {
    final bundle = await ContentRepository.instance.load();
    if (!mounted) return;
    setState(() {
      _stageQuizCount = widget.stageId.isEmpty
          ? bundle.quizzes.length
          : bundle.quizzes.where((q) => q.stage == widget.stageId).length;
      if (widget.item.bookId.isNotEmpty) {
        final match = bundle.books.where((b) => b.id == widget.item.bookId);
        if (match.isNotEmpty) _book = match.first;
      }
      if (widget.item.memoId.isNotEmpty) {
        final match = bundle.memorizationItems
            .where((m) => m.id == widget.item.memoId);
        if (match.isNotEmpty) _memo = match.first;
      }
    });
  }

  Future<void> _pickStatus() async {
    final selected = await showStatusPicker(context, _status);
    if (selected == null) return;
    await _progress.setStatus(widget.item.id, selected);
    if (!mounted) return;
    setState(() => _status = selected);
  }

  Future<void> _logStudy() async {
    final minutes = widget.item.estimatedMinutes > 0
        ? widget.item.estimatedMinutes
        : 15;
    final total = await _progress.addStudyMinutes(minutes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$minutes মিনিট যোগ হয়েছে। আজ মোট: $total মিনিট')),
    );
  }

  Future<void> _startQuiz() async {
    final bundle = await ContentRepository.instance.load();
    final questions = widget.stageId.isEmpty
        ? bundle.quizzes
        : bundle.quizzes.where((q) => q.stage == widget.stageId).toList();
    if (!mounted) return;
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এই ধাপের জন্য এখনো কোনো প্রশ্ন যোগ করা হয়নি।')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizPlayScreen(
          title: widget.item.title,
          questions: questions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(title: const Text('পাঠের বিবরণ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_stories_rounded,
                    color: AppColors.accent, size: 32),
                const SizedBox(height: 16),
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Chip(label: Text(item.type.labelBn)),
                    const SizedBox(width: 8),
                    StatusPill(status: _status),
                  ],
                ),
                if (item.author.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('লেখক: ${item.author}',
                      style: const TextStyle(color: Colors.white70)),
                ],
                if (item.estimatedMinutes > 0) ...[
                  const SizedBox(height: 6),
                  Text('আনুমানিক সময়: ${item.estimatedMinutes} মিনিট',
                      style: const TextStyle(color: Colors.white70)),
                ],
                const SizedBox(height: 16),
                Text(
                  item.description.isEmpty
                      ? 'এখানে পাঠের নোট, নির্দেশনা বা সারাংশ থাকবে।'
                      : item.description,
                  style: const TextStyle(height: 1.6, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStatus,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('অবস্থা'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _logStudy,
                  icon: const Icon(Icons.timer_outlined, size: 18),
                  label: const Text('পড়া লগ করো'),
                ),
              ),
            ],
          ),
          if (widget.item.type == ItemType.assessment ||
              _stageQuizCount > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _startQuiz,
                icon: const Icon(Icons.quiz_rounded, size: 18),
                label: Text(_stageQuizCount > 0
                    ? 'পরীক্ষা দাও ($_stageQuizCountটি প্রশ্ন)'
                    : 'কুইজ শুরু করো'),
              ),
            ),
          ],
          if (_memo != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MemorizationPracticeScreen(item: _memo!),
                  ),
                ),
                icon: const Icon(Icons.auto_stories_rounded, size: 18),
                label: const Text('মুখস্থ অনুশীলন করো'),
              ),
            ),
          ],
          if (_book != null) ...[
            const SizedBox(height: 18),
            const Text('সম্পর্কিত বই',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book_rounded,
                    color: AppColors.accent),
                title: Text(_book!.title),
                subtitle: Text('ডিজিটাল লাইব্রেরিতে দেখো • ${_book!.format.labelBn}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BookDetailScreen(book: _book!),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
