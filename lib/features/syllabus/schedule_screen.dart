import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/schedule.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';

/// Read-only view of the official 2025–2027 monthly study schedule.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key, required this.schedule});

  final ScheduleData schedule;

  Future<void> _openSource(BuildContext context) async {
    final url = schedule.sourceUrl;
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('লিংক খোলা যায়নি: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('অধ্যয়ন সূচি',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: schedule.isEmpty
          ? const EmptyState(
              icon: Icons.event_note_outlined,
              title: 'সূচি পাওয়া যায়নি',
              message: 'GitHub-এর schedule.json ফাইলে সূচি যোগ করলে এখানে দেখা যাবে।',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                Text(
                  schedule.title.isEmpty
                      ? 'কর্মীদের পাঠ মূল্যায়ন ও অধ্যয়ন সিলেবাস'
                      : schedule.title,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800, height: 1.4),
                ),
                if (schedule.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(schedule.subtitle,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13)),
                ],
                if (schedule.sourceUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openSource(context),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: Text(
                        schedule.sourceLabel.isEmpty
                            ? 'সম্পূর্ণ সিলেবাস দেখুন'
                            : schedule.sourceLabel,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ...schedule.years.map(
                  (year) => _YearSection(year: year),
                ),
                if (schedule.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const SectionHeader(
                    title: 'অতিরিক্ত নির্দেশনা',
                    subtitle: 'মাসিক ও বার্ষিক লক্ষ্য',
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final note in schedule.notes)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 5),
                                    child: Icon(Icons.circle,
                                        size: 6, color: AppColors.accent),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      note,
                                      style: const TextStyle(
                                          height: 1.6,
                                          color: Colors.white70,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _YearSection extends StatelessWidget {
  const _YearSection({required this.year});
  final ScheduleYear year;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x22FF3B5C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  year.year,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.accent),
                ),
              ),
              const SizedBox(width: 10),
              Text('${year.months.length} মাস',
                  style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
            ],
          ),
        ),
        ...year.months.map(
          (month) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MonthCard(month: month),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.month});
  final ScheduleMonth month;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                color: AppColors.accent, size: 20),
          ),
          title: Text(month.month,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
          subtitle: month.quran.isEmpty
              ? null
              : Text(month.quran,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
          children: [
            _DetailRow(label: 'কুরআন', value: month.quran),
            _DetailRow(label: 'হাদিস', value: month.hadith),
            if (month.literature.isNotEmpty)
              _DetailRow(
                  label: 'সাহিত্য', value: month.literature.join(' • ')),
            _DetailRow(label: 'আলোচনা', value: month.discussion),
            if (month.practice.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('চর্চা',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.accent)),
              ),
              const SizedBox(height: 8),
              ...month.practice.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(Icons.check_circle_outline,
                            size: 14, color: AppColors.success),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5),
                            children: [
                              TextSpan(
                                text: '${p.label}: ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                              TextSpan(text: p.value),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
