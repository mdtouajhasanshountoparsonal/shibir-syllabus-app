import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/content_manifest.dart';
import '../../data/models/syllabus.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/memorization_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import '../library/library_screen.dart';
import '../memorization/memorization_screen.dart';
import '../quiz/quiz_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../quran_learning/widgets/quran_learning_tile.dart';
import '../syllabus/item_detail_screen.dart';
import '../syllabus/schedule_screen.dart';
import '../syllabus/stage_screen.dart';
import 'bookmarks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ContentBundle _bundle = const ContentBundle.empty();
  bool _loading = true;

  final _content = ContentRepository.instance;
  final _progress = ProgressRepository.instance;
  final _memo = MemorizationRepository.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bundle = await _content.load();
    if (!mounted) return;
    setState(() {
      _bundle = bundle;
      _loading = false;
    });
  }

  List<SyllabusItem> get _allItems =>
      _bundle.stages.expand((s) => s.items).toList(growable: false);

  void _openItem(SyllabusItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final items = _allItems;
    final completed = _progress.completedCount(items.map((i) => i.id));
    final ratio = items.isEmpty ? 0.0 : completed / items.length;
    final continueItem = _progress.continueCandidate(items);
    final continueSource = continueItem == null
        ? null
        : items.firstWhere(
            (i) => i.id == continueItem.itemId,
            orElse: () => items.first,
          );

    final dueCount = _memo.dueItems(_bundle.memorizationItems).length;
    final todayMinutes = _progress.todayReadMinutes;
    final goal = _progress.dailyGoalMinutes;
    final goalRatio = goal == 0 ? 0.0 : (todayMinutes / goal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConstants.appName,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(AppConstants.appTagline,
                style: TextStyle(fontSize: 11.5, color: Colors.white54)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'খোঁজো',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SearchScreen(bundle: _bundle),
              ),
            ),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'সেটিংস',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: [
            _DashboardCard(
              todayMinutes: todayMinutes,
              goalMinutes: goal,
              goalRatio: goalRatio,
              streak: _progress.dailyStreak,
              overallRatio: ratio,
              completed: completed,
              total: items.length,
              continueTitle: continueSource?.title,
              onContinue: continueSource == null
                  ? null
                  : () => _openItem(continueSource),
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'দ্রুত অ্যাক্সেস'),
            const SizedBox(height: 12),
            _QuickAccessGrid(
              onBooks: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LibraryScreen(initialBundle: _bundle),
                ),
              ),
              onToday: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TodayScreen(bundle: _bundle),
                ),
              ),
              onRevision: () => widget.onNavigate(3),
              onBookmarks: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookmarksScreen(bundle: _bundle),
                ),
              ),
              onMemorization: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MemorizationScreen(bundle: _bundle),
                ),
              ),
              onQuiz: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuizListScreen(bundle: _bundle),
                ),
              ),
              onSchedule: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ScheduleScreen(schedule: _bundle.schedule),
                ),
              ),
              dueCount: dueCount,
            ),
            const SizedBox(height: 22),
            const SectionHeader(
              title: 'কর্মী সিলেবাসের বিষয়',
              subtitle: '৭টি বিষয় — পাঠ্যবই ও গ্রন্থনির্দেশনা',
            ),
            const SizedBox(height: 12),
            ..._bundle.stages.map(
              (stage) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StageCard(
                  stage: stage,
                  completed: _progress.completedCount(
                    stage.items.map((i) => i.id),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StageScreen(stage: stage),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'সূত্র: icsbook.info ও shibircloud.com — কর্মীদের পাঠ মূল্যায়ন ও অধ্যয়ন সিলেবাস। তথ্য যাচাই করে ব্যবহার করো।',
              style: TextStyle(color: Colors.white38, fontSize: 11.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.todayMinutes,
    required this.goalMinutes,
    required this.goalRatio,
    required this.streak,
    required this.overallRatio,
    required this.completed,
    required this.total,
    this.continueTitle,
    this.onContinue,
  });

  final int todayMinutes;
  final int goalMinutes;
  final double goalRatio;
  final int streak;
  final double overallRatio;
  final int completed;
  final int total;
  final String? continueTitle;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF7F1830), Color(0xFF25131D), Color(0xFF141A22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x44FF3B5C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded,
                  color: AppColors.accent, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('আজকের পড়ার লক্ষ্য',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('$todayMinutes / $goalMinutes মিনিট',
                        style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
                  ],
                ),
              ),
              if (streak > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          size: 15, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text('$streak দিন',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LabeledProgress(
            label: 'আজকের অগ্রগতি',
            value: goalRatio,
            trailing: '${(goalRatio * 100).round()}%',
          ),
          const SizedBox(height: 16),
          LabeledProgress(
            label: 'মোট সিলেবাস অগ্রগতি ($completed/$total)',
            value: overallRatio,
            color: AppColors.success,
          ),
          if (onContinue != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  'চালিয়ে যাও: ${continueTitle ?? ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({
    required this.onBooks,
    required this.onToday,
    required this.onRevision,
    required this.onBookmarks,
    required this.onMemorization,
    required this.onQuiz,
    required this.onSchedule,
    required this.dueCount,
  });

  final VoidCallback onBooks;
  final VoidCallback onToday;
  final VoidCallback onRevision;
  final VoidCallback onBookmarks;
  final VoidCallback onMemorization;
  final VoidCallback onQuiz;
  final VoidCallback onSchedule;
  final int dueCount;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _QuickTile(
        icon: Icons.search_rounded,
        label: 'বই খোঁজো',
        color: AppColors.info,
        onTap: onBooks,
      ),
      _QuickTile(
        icon: Icons.calendar_month_rounded,
        label: 'মাসিক সূচি',
        color: AppColors.accent,
        onTap: onSchedule,
      ),
      _QuickTile(
        icon: Icons.today_rounded,
        label: 'আজকের কাজ',
        color: AppColors.success,
        onTap: onToday,
      ),
      _QuickTile(
        icon: Icons.replay_rounded,
        label: 'মুখস্থ রিভিশন',
        color: AppColors.purple,
        badge: dueCount,
        onTap: onMemorization,
      ),
      _QuickTile(
        icon: Icons.quiz_rounded,
        label: 'পরীক্ষা',
        color: AppColors.danger,
        onTap: onQuiz,
      ),
      _QuickTile(
        icon: Icons.bookmark_rounded,
        label: 'বুকমার্ক',
        color: AppColors.warning,
        onTap: onBookmarks,
      ),
      _QuickTile(
        icon: Icons.insights_rounded,
        label: 'আজকের রিভিশন',
        color: AppColors.accent,
        onTap: onRevision,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [...tiles, const QuranLearningTile()],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const Spacer(),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$badge',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.completed,
    required this.onTap,
  });

  final SyllabusStage stage;
  final int completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = stage.items.length;
    final ratio = total == 0 ? 0.0 : completed / total;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0x22FF3B5C),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stage.title,
                        style: const TextStyle(
                            fontSize: 16.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(stage.subtitle,
                        style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 5,
                        backgroundColor: Colors.white12,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('$completed/$total সম্পন্ন',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white54)),
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

/// Small screen listing today's tasks.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.bundle});
  final ContentBundle bundle;

  @override
  Widget build(BuildContext context) {
    final items = bundle.stages.expand((s) => s.items).toList(growable: false);
    final continueItem = ProgressRepository.instance.continueCandidate(items);
    final due = MemorizationRepository.instance.dueItems(bundle.memorizationItems);

    return Scaffold(
      appBar: AppBar(title: const Text('আজকের কাজ')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SectionHeader(title: 'পড়া চালিয়ে যাও'),
          const SizedBox(height: 8),
          if (continueItem == null)
            const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'চলমান কোনো পাঠ নেই',
              message: 'সিলেবাস থেকে একটি বিষয় "পড়ছি" হিসেবে চিহ্নিত করো।',
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.play_circle_outline,
                    color: AppColors.accent),
                title: Text(continueItem.itemId),
                onTap: () {
                  final item = items.firstWhere(
                    (i) => i.id == continueItem.itemId,
                    orElse: () => items.first,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(item: item),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 22),
          SectionHeader(title: 'আজকের রিভিশন (${due.length})'),
          const SizedBox(height: 8),
          if (due.isEmpty)
            const EmptyState(
              icon: Icons.event_available,
              title: 'আজ কোনো রিভিশন বাকি নেই',
            )
          else
            ...due.map(
              (m) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.replay_rounded,
                      color: AppColors.purple),
                  title: Text(m.title),
                  subtitle: const Text('আজ পুনরাবৃত্তি'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
