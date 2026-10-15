import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/content_manifest.dart';
import '../../data/models/enums.dart';
import '../../data/models/syllabus.dart';
import '../../data/repositories/progress_repository.dart';
import 'item_detail_screen.dart';

/// Detail view for a top-level program (কর্মী / সাথী / সদস্য সিলেবাস).
///
/// Shows the official heading, a link to the full syllabus PDF and a
/// tree/spider-web view of subjects → goals → resource groups → items.
class ProgramScreen extends StatefulWidget {
  const ProgramScreen({
    super.key,
    required this.program,
    required this.bundle,
  });

  final SyllabusProgram program;
  final ContentBundle bundle;

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  final _progress = ProgressRepository.instance;

  Color get _accent {
    final v = widget.program.colorValue;
    return v == 0 ? AppColors.accent : Color(v);
  }

  List<SyllabusStage> get _subjects {
    final byId = {for (final s in widget.bundle.stages) s.id: s};
    return [
      for (final id in widget.program.stageIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  List<String> _itemIds(List<SyllabusStage> subjects) => [
        for (final s in subjects)
          for (final i in s.items) i.id,
      ];

  Future<void> _openSource() async {
    final url = widget.program.sourceUrl;
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('লিংক খোলা যায়নি।')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _subjects;
    final ids = _itemIds(subjects);
    final done = _progress.completedCount(ids);
    final total = ids.length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.program.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          _Header(
            program: widget.program,
            accent: _accent,
            done: done,
            total: total,
            onOpenSource: widget.program.sourceUrl.isEmpty ? null : _openSource,
          ),
          const SizedBox(height: 20),
          const Text('বিষয়ভিত্তিক সিলেবাস',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('যেকোনো বিষয়, লক্ষ্য বা বইয়ে চাপ দিয়ে বিস্তারিত দেখুন।',
              style: TextStyle(color: Colors.white54, fontSize: 12.5)),
          const SizedBox(height: 14),
          if (subjects.isEmpty)
            const _EmptyProgram()
          else
            for (var i = 0; i < subjects.length; i++)
              _SubjectNode(
                index: i + 1,
                stage: subjects[i],
                accent: _accent,
                isLast: i == subjects.length - 1,
                progress: _progress,
                onTapItem: _openItem,
                onChanged: () => setState(() {}),
              ),
        ],
      ),
    );
  }

  void _openItem(SyllabusItem item, String stageId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(item: item, stageId: stageId),
      ),
    );
  }
}

// --- Header -----------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.program,
    required this.accent,
    required this.done,
    required this.total,
    this.onOpenSource,
  });

  final SyllabusProgram program;
  final Color accent;
  final int done;
  final int total;
  final VoidCallback? onOpenSource;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.28), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.account_tree_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  program.heading.isEmpty ? program.title : program.heading,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, height: 1.35),
                ),
              ),
            ],
          ),
          if (program.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(program.description,
                style: const TextStyle(
                    color: Colors.white70, height: 1.6, fontSize: 12.5)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 9,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$done/$total',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text('সম্পূর্ণ সিলেবাসের অগ্রগতি (${(fraction * 100).round()}%)',
              style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
          if (onOpenSource != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenSource,
                style: FilledButton.styleFrom(backgroundColor: accent),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('সম্পূর্ণ সিলেবাস দেখুন'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyProgram extends StatelessWidget {
  const _EmptyProgram();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_empty_rounded, color: Colors.white54),
          SizedBox(width: 12),
          Expanded(
            child: Text('এই সিলেবাসের বিস্তারিত শীঘ্রই যোগ করা হবে।',
                style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

// --- Tree nodes -------------------------------------------------------------

class _SubjectNode extends StatefulWidget {
  const _SubjectNode({
    required this.index,
    required this.stage,
    required this.accent,
    required this.isLast,
    required this.progress,
    required this.onTapItem,
    required this.onChanged,
  });

  final int index;
  final SyllabusStage stage;
  final Color accent;
  final bool isLast;
  final ProgressRepository progress;
  final void Function(SyllabusItem, String) onTapItem;
  final VoidCallback onChanged;

  @override
  State<_SubjectNode> createState() => _SubjectNodeState();
}

class _SubjectNodeState extends State<_SubjectNode> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;
    final ids = stage.items.map((i) => i.id).toList();
    final done = widget.progress.completedCount(ids);
    final total = ids.length;

    final groups = <String, List<SyllabusItem>>{};
    for (final item in stage.items) {
      groups.putIfAbsent(item.category, () => []).add(item);
    }
    final orderedGroups = groups.keys.toList()
      ..sort((a, b) => _categoryRank(a).compareTo(_categoryRank(b)));

    return _TreeRow(
      isLast: widget.isLast,
      color: widget.accent.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SubjectCard(
              index: widget.index,
              stage: stage,
              accent: widget.accent,
              done: done,
              total: total,
              expanded: _expanded,
              onToggle: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded)
              _TreeRow(
                isLast: true,
                color: widget.accent.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stage.goals.isNotEmpty) ...[
                        _MiniLabel(
                            icon: Icons.flag_rounded,
                            text: 'লক্ষ্য ও উদ্দেশ্য',
                            accent: widget.accent),
                        const SizedBox(height: 6),
                        for (final goal in stage.goals)
                          _Bullet(text: goal, accent: widget.accent),
                        const SizedBox(height: 12),
                      ],
                      for (var g = 0; g < orderedGroups.length; g++)
                        _GroupNode(
                          category: orderedGroups[g],
                          items: groups[orderedGroups[g]]!,
                          accent: widget.accent,
                          stageId: stage.id,
                          onTapItem: widget.onTapItem,
                          onChanged: widget.onChanged,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static int _categoryRank(String category) {
    const order = [
      'অধ্যয়ন',
      'পাঠ্যবই',
      'গ্রন্থনির্দেশনা',
      'কুরআন মুখস্থ নির্দেশনা',
      'বিবিধ',
    ];
    final i = order.indexOf(category);
    return i < 0 ? order.length : i;
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.index,
    required this.stage,
    required this.accent,
    required this.done,
    required this.total,
    required this.expanded,
    required this.onToggle,
  });

  final int index;
  final SyllabusStage stage;
  final Color accent;
  final int done;
  final int total;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$index',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: accent)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stage.title,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w800)),
                    if (stage.subtitle.isNotEmpty)
                      Text(stage.subtitle,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('$done/$total',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: accent, fontSize: 12.5)),
              Icon(expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupNode extends StatelessWidget {
  const _GroupNode({
    required this.category,
    required this.items,
    required this.accent,
    required this.stageId,
    required this.onTapItem,
    required this.onChanged,
  });

  final String category;
  final List<SyllabusItem> items;
  final Color accent;
  final String stageId;
  final void Function(SyllabusItem, String) onTapItem;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniLabel(
              icon: Icons.label_important_rounded,
              text: category.isEmpty ? 'বিবিধ' : category,
              accent: accent),
          const SizedBox(height: 4),
          _TreeRow(
            isLast: true,
            color: accent.withValues(alpha: 0.25),
            child: Column(
              children: [
                for (final item in items)
                  _ItemTile(
                    item: item,
                    onTap: () => onTapItem(item, stageId),
                    onChanged: onChanged,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatefulWidget {
  const _ItemTile({
    required this.item,
    required this.onTap,
    required this.onChanged,
  });

  final SyllabusItem item;
  final VoidCallback onTap;
  final VoidCallback onChanged;

  @override
  State<_ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<_ItemTile> {
  final _progress = ProgressRepository.instance;

  bool get _done =>
      _progress.get(widget.item.id).status == StudyStatus.completed;

  Future<void> _toggle() async {
    final next = _done ? StudyStatus.notStarted : StudyStatus.completed;
    await _progress.setStatus(widget.item.id, next);
    if (!mounted) return;
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final done = _done;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(_iconFor(item.type), size: 17, color: Colors.white54),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: done ? Colors.white54 : null,
                          decoration: done ? TextDecoration.lineThrough : null)),
                  if (item.author.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(item.author,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11.5)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: done ? 'সম্পন্ন (ট্যাপ করে বাতিল করো)' : 'সম্পন্ন হিসেবে চিহ্নিত করো',
              child: InkResponse(
                onTap: _toggle,
                radius: 22,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color: done ? AppColors.success : Colors.white38,
                  ),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(ItemType type) {
    switch (type) {
      case ItemType.quran:
        return Icons.menu_book_rounded;
      case ItemType.hadith:
        return Icons.auto_stories_rounded;
      case ItemType.memorization:
        return Icons.psychology_rounded;
      case ItemType.book:
        return Icons.book_rounded;
      case ItemType.assessment:
        return Icons.quiz_rounded;
      case ItemType.other:
        return Icons.article_rounded;
    }
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: accent),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: accent.withValues(alpha: 0.95))),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration:
                  BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.8, height: 1.5, color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

// --- Connector --------------------------------------------------------------

/// Draws a tree connector (vertical trunk + branch stub) to the left of a child.
class _TreeRow extends StatelessWidget {
  const _TreeRow({
    required this.child,
    required this.isLast,
    required this.color,
  });

  final Widget child;
  final bool isLast;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: CustomPaint(
              painter: _BranchPainter(isLast: isLast, color: color),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BranchPainter extends CustomPainter {
  _BranchPainter({required this.isLast, required this.color});

  final bool isLast;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const x = 12.0;
    const midY = 20.0;
    canvas.drawLine(Offset(x, 0), Offset(x, isLast ? midY : size.height), paint);
    canvas.drawLine(Offset(x, midY), Offset(x + 12, midY), paint);
    canvas.drawCircle(Offset(x, midY), 2.4,
        Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_BranchPainter old) =>
      old.isLast != isLast || old.color != color;
}
