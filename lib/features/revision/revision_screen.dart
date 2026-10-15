import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/content_manifest.dart';
import '../../data/models/memorization.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/memorization_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import '../memorization/memorization_screen.dart';

class RevisionScreen extends StatefulWidget {
  const RevisionScreen({super.key});

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> {
  ContentBundle? _bundle;
  final _memo = MemorizationRepository.instance;

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

  Future<void> _openPractice(MemorizationItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemorizationPracticeScreen(item: item),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    if (bundle == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    final progress = _memo.all();

    final due = <MemorizationItem>[];
    final upcoming = <MapEntry<MemorizationItem, DateTime>>[];

    for (final item in bundle.memorizationItems) {
      final p = progress[item.id];
      if (p == null || p.nextReview == null) continue;
      if (!p.nextReview!.isAfter(now)) {
        due.add(item);
      } else {
        upcoming.add(MapEntry(item, p.nextReview!));
      }
    }
    upcoming.sort((a, b) => a.value.compareTo(b.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('রিভিশন',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            _SummaryBanner(
              dueCount: due.length,
              memorizedCount: _memo.memorizedCount,
              streak: _memo.reviewStreak,
            ),
            const SizedBox(height: 20),
            SectionHeader(
              title: 'আজকের রিভিশন (${due.length})',
              subtitle: 'স্পেসড রিপিটিশন সূচি অনুযায়ী',
            ),
            const SizedBox(height: 10),
            if (due.isEmpty)
              const EmptyState(
                icon: Icons.event_available_rounded,
                title: 'আজ কোনো রিভিশন নেই',
                message: 'মুখস্থ আইটেম শুরু করলে সূচি এখানে দেখা যাবে।',
              )
            else
              ...due.map(
                (item) => _ReviewTile(
                  item: item,
                  label: 'আজ',
                  highlight: true,
                  onTap: () => _openPractice(item),
                ),
              ),
            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: 22),
              const SectionHeader(title: 'আসন্ন রিভিশন'),
              const SizedBox(height: 10),
              ...upcoming.map(
                (entry) => _ReviewTile(
                  item: entry.key,
                  label: DateUtilsX.relativeBn(entry.value),
                  highlight: false,
                  onTap: () => _openPractice(entry.key),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.dueCount,
    required this.memorizedCount,
    required this.streak,
  });

  final int dueCount;
  final int memorizedCount;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3A1F5C), Color(0xFF1A1327), Color(0xFF141A22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x449B7BFF)),
      ),
      child: Row(
        children: [
          _stat('$dueCount', 'আজ বাকি', AppColors.warning),
          _divider(),
          _stat('$memorizedCount', 'মুখস্থ', AppColors.success),
          _divider(),
          _stat('$streak', 'দিন ধারা', AppColors.purple),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: Colors.white12);

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 11.5, color: Colors.white54)),
          ],
        ),
      );
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.item,
    required this.label,
    required this.highlight,
    required this.onTap,
  });

  final MemorizationItem item;
  final String label;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (highlight ? AppColors.warning : AppColors.purple)
                  .withValues(alpha: 0.18),
          child: Icon(
            Icons.replay_rounded,
            color: highlight ? AppColors.warning : AppColors.purple,
            size: 20,
          ),
        ),
        title: Text(item.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(item.reference.isEmpty ? label : '${item.reference} • $label'),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}
