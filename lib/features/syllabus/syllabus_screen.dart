import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/content_manifest.dart';
import '../../data/models/syllabus.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../shared/widgets/section_header.dart';
import '../quiz/quiz_screen.dart';
import 'program_screen.dart';
import 'schedule_screen.dart';
import 'stage_screen.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  ContentBundle _bundle = const ContentBundle.empty();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bundle = await ContentRepository.instance.load();
    if (!mounted) return;
    setState(() {
      _bundle = bundle;
      _loading = false;
    });
  }

  (int, int) _programProgress(SyllabusProgram program) {
    final stages =
        _bundle.stages.where((s) => program.stageIds.contains(s.id));
    final ids = [
      for (final s in stages)
        for (final i in s.items) i.id,
    ];
    return (ProgressRepository.instance.completedCount(ids), ids.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('সিলেবাস',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  if (!_bundle.schedule.isEmpty) ...[
                    _ScheduleBanner(
                      years: _bundle.schedule.years.length,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ScheduleScreen(schedule: _bundle.schedule),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_bundle.quizzes.isNotEmpty) ...[
                    _QuizBanner(
                      count: _bundle.quizzes.length,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuizListScreen(bundle: _bundle),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (_bundle.programs.isNotEmpty) ...[
                    const SectionHeader(
                      title: 'সিলেবাস',
                      subtitle: 'কর্মী • সাথী • সদস্য — পর্যায়ভিত্তিক পাঠ্যক্রম',
                    ),
                    const SizedBox(height: 12),
                    ..._bundle.programs.map((program) {
                      final progress = _programProgress(program);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ProgramCard(
                          program: program,
                          done: progress.$1,
                          total: progress.$2,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProgramScreen(
                                  program: program,
                                  bundle: _bundle,
                                ),
                              ),
                            );
                            _load();
                          },
                        ),
                      );
                    }),
                  ] else ...[
                    const SectionHeader(
                      title: 'বিষয়ভিত্তিক অধ্যয়ন',
                      subtitle:
                          'কর্মী সিলেবাসের ৭টি বিষয় — পাঠ্যবই ও গ্রন্থনির্দেশনা',
                    ),
                    const SizedBox(height: 12),
                    ..._bundle.stages.map(
                      (stage) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _StageSection(
                          stage: stage,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StageScreen(stage: stage),
                              ),
                            );
                            _load();
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.done,
    required this.total,
    required this.onTap,
  });

  final SyllabusProgram program;
  final int done;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent =
        program.colorValue == 0 ? AppColors.accent : Color(program.colorValue);
    final fraction = total == 0 ? 0.0 : done / total;
    final pct = (fraction * 100).round();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.30), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: fraction,
                        strokeWidth: 5,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                    Text('$pct%',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: accent)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(program.title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    if (program.subtitle.isNotEmpty)
                      Text(program.subtitle,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Text(
                      total == 0
                          ? 'শীঘ্রই বিস্তারিত যুক্ত হবে'
                          : '$done/$total সম্পন্ন',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizBanner extends StatelessWidget {
  const _QuizBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF14406B), Color(0xFF141A22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x444DA3FF)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.quiz_rounded, color: AppColors.info),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('পরীক্ষা ও কুইজ',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('$countটি প্রশ্ন — নিজের বোঝাপড়া যাচাই করো',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleBanner extends StatelessWidget {
  const _ScheduleBanner({required this.years, required this.onTap});

  final int years;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF7F1830), Color(0xFF25131D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x44FF3B5C)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('মাসভিত্তিক অধ্যয়ন সূচি',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('২০২৫ – ২০২৭ • কুরআন, হাদিস, সাহিত্য ও চর্চা',
                        style: TextStyle(color: Colors.white60, fontSize: 12.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageSection extends StatelessWidget {
  const _StageSection({required this.stage, required this.onTap});

  final SyllabusStage stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressRepository.instance;
    final completed = progress.completedCount(stage.items.map((i) => i.id));
    final total = stage.items.length;

    final byType = <String, int>{};
    for (final item in stage.items) {
      byType[item.type.labelBn] = (byType[item.type.labelBn] ?? 0) + 1;
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0x22FF3B5C),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.account_tree_rounded,
                        color: AppColors.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stage.title,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        Text(stage.subtitle,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Text('$completed/$total',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 14),
              Text(stage.description,
                  style: const TextStyle(
                      color: Colors.white60, height: 1.5, fontSize: 12.5)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: byType.entries
                    .map(
                      (e) => Chip(
                        label: Text('${e.key} • ${e.value}'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
