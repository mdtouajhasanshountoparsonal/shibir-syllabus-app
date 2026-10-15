import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/content_manifest.dart';
import '../../data/models/enums.dart';
import '../../data/models/syllabus.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/memorization_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_tile.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ContentBundle? _bundle;
  final _progress = ProgressRepository.instance;
  final _memo = MemorizationRepository.instance;
  final _library = LibraryRepository.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bundle = await ContentRepository.instance.load();
    if (!mounted) return;
    setState(() => _bundle = bundle);
  }

  Future<void> _setGoal() async {
    final controller =
        TextEditingController(text: _progress.dailyGoalMinutes.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('দৈনিক লক্ষ্য (মিনিট)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(controller.text)),
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) {
      await _progress.setDailyGoal(value);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    if (bundle == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final items = bundle.stages.expand((s) => s.items).toList(growable: false);
    final statusCounts = <StudyStatus, int>{};
    for (final item in items) {
      final s = _progress.get(item.id).status;
      statusCounts[s] = (statusCounts[s] ?? 0) + 1;
    }
    final completed = statusCounts[StudyStatus.completed] ?? 0;
    final overall = items.isEmpty ? 0.0 : completed / items.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('আমার অগ্রগতি',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'দৈনিক লক্ষ্য',
            onPressed: _setGoal,
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            _OverallCard(
              ratio: overall,
              completed: completed,
              total: items.length,
            ),
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [
                StatTile(
                  icon: Icons.timer_outlined,
                  value: '${_progress.todayReadMinutes}',
                  label: 'আজ পড়া (মিনিট)',
                  color: AppColors.accent,
                ),
                StatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '${_progress.dailyStreak}',
                  label: 'পড়ার ধারা (দিন)',
                  color: AppColors.warning,
                ),
                StatTile(
                  icon: Icons.psychology_rounded,
                  value: '${_memo.memorizedCount}',
                  label: 'মুখস্থ সম্পন্ন',
                  color: AppColors.purple,
                ),
                StatTile(
                  icon: Icons.sticky_note_2_outlined,
                  value: '${_library.totalNotes}',
                  label: 'মোট নোট',
                  color: AppColors.info,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'অবস্থা অনুযায়ী'),
            const SizedBox(height: 10),
            ...StudyStatus.values.map(
              (status) => _StatusRow(
                status: status,
                count: statusCounts[status] ?? 0,
                total: items.length,
              ),
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'স্তরভিত্তিক অগ্রগতি'),
            const SizedBox(height: 10),
            ...bundle.stages.map(
              (stage) => _StageProgress(
                stage: stage,
                completed:
                    _progress.completedCount(stage.items.map((i) => i.id)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({
    required this.ratio,
    required this.completed,
    required this.total,
  });

  final double ratio;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF103A2A), Color(0xFF12241C), Color(0xFF141A22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x443DD68C)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 8,
                    backgroundColor: Colors.white12,
                    color: AppColors.success,
                  ),
                ),
                Text('${(ratio * 100).round()}%',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('মোট সিলেবাস অগ্রগতি',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('$completed / $total সম্পন্ন',
                    style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 6),
                Text(DateUtilsX.pretty(DateTime.now()),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.status,
    required this.count,
    required this.total,
  });

  final StudyStatus status;
  final int count;
  final int total;

  Color get _color {
    switch (status) {
      case StudyStatus.notStarted:
        return Colors.white54;
      case StudyStatus.reading:
        return AppColors.info;
      case StudyStatus.completed:
        return AppColors.success;
      case StudyStatus.needsRevision:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(status.labelBn,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text('$count',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.white12,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageProgress extends StatelessWidget {
  const _StageProgress({required this.stage, required this.completed});
  final SyllabusStage stage;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final total = stage.items.length;
    final ratio = total == 0 ? 0.0 : completed / total;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(stage.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('$completed/$total',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: Colors.white12,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
