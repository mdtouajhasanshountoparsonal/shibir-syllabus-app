import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';
import '../../data/models/syllabus.dart';
import '../../data/repositories/progress_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/status_pill.dart';
import 'item_detail_screen.dart';

/// Lets the user pick a [StudyStatus] for an item.
Future<StudyStatus?> showStatusPicker(
  BuildContext context,
  StudyStatus current,
) {
  return showModalBottomSheet<StudyStatus>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('পড়ার অবস্থা নির্বাচন করো',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            ...StudyStatus.values.map(
              (status) => ListTile(
                leading: Icon(
                  status == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: status == current ? AppColors.accent : Colors.white38,
                ),
                title: Text(status.labelBn),
                onTap: () => Navigator.of(context).pop(status),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class StageScreen extends StatefulWidget {
  const StageScreen({super.key, required this.stage});
  final SyllabusStage stage;

  @override
  State<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends State<StageScreen> {
  final _progress = ProgressRepository.instance;
  Map<String, StudyStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final map = <String, StudyStatus>{};
    for (final item in widget.stage.items) {
      map[item.id] = _progress.get(item.id).status;
    }
    setState(() => _statuses = map);
  }

  Future<void> _changeStatus(SyllabusItem item) async {
    final selected = await showStatusPicker(
      context,
      _statuses[item.id] ?? StudyStatus.notStarted,
    );
    if (selected == null) return;
    await _progress.setStatus(item.id, selected);
    if (!mounted) return;
    setState(() => _statuses[item.id] = selected);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.stage.items.length;
    final done = _statuses.values
        .where((s) => s == StudyStatus.completed)
        .length;
    final ratio = total == 0 ? 0.0 : done / total;

    return Scaffold(
      appBar: AppBar(title: Text(widget.stage.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Text(widget.stage.description,
              style: const TextStyle(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: Colors.white12,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text('$done/$total সম্পন্ন',
              style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 18),
          if (widget.stage.items.isEmpty)
            const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'এখনো কোনো আইটেম যোগ করা হয়নি',
              message: 'GitHub-এর stages.json ফাইলে আইটেম যোগ করলে এখানে দেখা যাবে।',
            ),
          ...widget.stage.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ItemCard(
                item: item,
                status: _statuses[item.id] ?? StudyStatus.notStarted,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(
                        item: item,
                        stageId: widget.stage.id,
                      ),
                    ),
                  );
                  _load();
                },
                onChangeStatus: () => _changeStatus(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.status,
    required this.onTap,
    required this.onChangeStatus,
  });

  final SyllabusItem item;
  final StudyStatus status;
  final VoidCallback onTap;
  final VoidCallback onChangeStatus;

  IconData get _icon {
    switch (item.type) {
      case ItemType.book:
        return Icons.menu_book_rounded;
      case ItemType.quran:
        return Icons.auto_stories_rounded;
      case ItemType.hadith:
        return Icons.format_quote_rounded;
      case ItemType.memorization:
        return Icons.psychology_rounded;
      case ItemType.assessment:
        return Icons.quiz_rounded;
      case ItemType.other:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: AppColors.accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.5)),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusPill(status: status, compact: true),
                        if (item.estimatedMinutes > 0) ...[
                          const SizedBox(width: 8),
                          Text('${item.estimatedMinutes} মিনিট',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white38)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'অবস্থা পরিবর্তন',
                onPressed: onChangeStatus,
                icon: const Icon(Icons.tune_rounded,
                    color: Colors.white38, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
