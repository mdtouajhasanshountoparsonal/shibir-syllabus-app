import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/backup_service.dart';

/// Export / import user data (progress, notes, bookmarks, memorization).
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _service = BackupService.instance;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _snack('সমস্যা হয়েছে: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareExport() => _run(() async {
        await _service.shareBackup();
      });

  Future<void> _copyExport() => _run(() async {
        await _service.copyToClipboard();
        _snack('ব্যাকআপ কপি হয়েছে। যেকোনো জায়গায় পেস্ট করে রাখো।');
      });

  Future<void> _importClipboard() => _run(() async {
        final summary = await _service.importFromClipboard();
        if (summary == null) {
          _snack('ক্লিপবোর্ডে কোনো ব্যাকআপ টেক্সট নেই।');
          return;
        }
        _showSummary(summary);
      });

  Future<void> _importLocalFile() => _run(() async {
        final raw = await _service.readLocalBackup();
        if (raw == null) {
          _snack('লোকাল ব্যাকআপ ফাইল পাওয়া যায়নি।');
          return;
        }
        final summary = await _service.restore(raw);
        _showSummary(summary);
      });

  void _showSummary(BackupSummary summary) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('পুনরুদ্ধার সম্পন্ন'),
        content: Text(
          'পাঠ অগ্রগতি: ${summary.reading}\n'
          'বই: ${summary.books}\n'
          'মুখস্থ: ${summary.memorization}\n'
          'সাম্প্রতিক খোঁজ: ${summary.recentSearches}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ব্যাকআপ ও পুনরুদ্ধার')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppColors.accent, size: 30),
                SizedBox(height: 14),
                Text('তোমার সব অগ্রগতি সুরক্ষিত রাখো',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                SizedBox(height: 8),
                Text(
                  'ব্যাকআপে থাকবে: পাঠের অবস্থা, বইয়ের শেষ পাতা, বুকমার্ক, '
                  'নোট, মুখস্থ রিভিশনের সূচি, দৈনিক লক্ষ্য ও স্ট্রিক।',
                  style: TextStyle(color: Colors.white60, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('ব্যাকআপ তৈরি করো',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _shareExport,
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('ব্যাকআপ ফাইল শেয়ার করো'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _copyExport,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('ব্যাকআপ টেক্সট কপি করো'),
            ),
          ),
          const SizedBox(height: 22),
          const Text('ব্যাকআপ থেকে ফিরিয়ে আনো',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _busy ? null : _importClipboard,
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: const Text('ক্লিপবোর্ড থেকে পুনরুদ্ধার'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _importLocalFile,
              icon: const Icon(Icons.restore_rounded, size: 18),
              label: const Text('লোকাল ব্যাকআপ ফাইল থেকে'),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 20),
          const Text(
            'নোট: পুনরুদ্ধার করলে একই আইডির বিদ্যমান অগ্রগতি ব্যাকআপের মান দিয়ে '
            'প্রতিস্থাপিত হবে। ডাউনলোড করা বইয়ের ফাইল আলাদা থাকে।',
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }
}
