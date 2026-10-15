import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/manifest_url_validator.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../services/local_store.dart';
import '../../services/notification_service.dart';
import '../../services/sync_service.dart';
import '../library/download_manager_screen.dart';
import 'backup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _content = ContentRepository.instance;
  final _progress = ProgressRepository.instance;
  final _notifications = NotificationService.instance;
  bool _syncing = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final enabled = _notifications.enabled;
    if (!mounted) return;
    setState(() {
      _reminderEnabled = enabled;
      _reminderTime = _notifications.time;
    });
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      final granted = await _notifications.requestPermission();
      if (!granted) {
        _snack('নোটিফিকেশন অনুমতি পাওয়া যায়নি। সেটিংস থেকে চালু করো।');
        return;
      }
      await _notifications.enable(_reminderTime);
    } else {
      await _notifications.disable();
    }
    if (!mounted) return;
    setState(() => _reminderEnabled = value);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked == null) return;
    setState(() => _reminderTime = picked);
    if (_reminderEnabled) {
      await _notifications.enable(picked);
    }
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    final result = await _content.sync();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.status == SyncStatus.failed
            ? AppColors.danger
            : AppColors.success,
      ),
    );
  }

  Future<void> _editUrl() async {
    final controller = TextEditingController(
      text: _content.isConfigured ? _content.manifestUrl : '',
    );
    final errorText = ValueNotifier<String?>(null);

    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('ম্যানিফেস্ট URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'তোমার কনটেন্ট রিপোর raw manifest.json লিংক বসাও।',
              style: TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.5),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<String?>(
              valueListenable: errorText,
              builder: (context, error, _) => TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText:
                      'https://raw.githubusercontent.com/USER/REPO/main/manifest.json',
                  border: const OutlineInputBorder(),
                  errorText: error,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_content.isConfigured)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop('__clear__'),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('URL মুছে ফেলো'),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () {
              final entered = controller.text.trim();
              final error = ManifestUrlValidator.validate(entered);
              if (error != null) {
                errorText.value = error;
                return;
              }
              Navigator.of(context).pop(entered);
            },
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );

    if (value == null) return;
    if (value == '__clear__') {
      await _content.clearManifestUrl();
    } else {
      await _content.setManifestUrl(value);
    }
    if (!mounted) return;
    setState(() {});
    if (value != '__clear__') {
      _snack('URL সংরক্ষণ হয়েছে। এখন "সিংক" চাপো।');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _resetCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('কনটেন্ট ক্যাশ মুছবে?'),
        content: const Text(
          'শুধু ডাউনলোড করা GitHub কনটেন্ট মুছে যাবে। তোমার পড়ার অগ্রগতি, নোট ও বুকমার্ক অক্ষত থাকবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('মুছে ফেলো'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await LocalStore.instance.clearContentCache();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('কনটেন্ট ক্যাশ মুছে ফেলা হয়েছে।')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lastSync = _content.lastSyncAt;
    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _card(
            title: 'GitHub কনটেন্ট সিংক',
            children: [
              _row('স্ট্যাটাস',
                  _content.isConfigured ? 'কনফিগার করা' : 'কনফিগার করা হয়নি'),
              _row('ক্যাশড ভার্সন',
                  _content.cachedVersion.isEmpty ? 'বান্ডেল' : _content.cachedVersion),
              _row('সর্বশেষ সিংক',
                  lastSync == null ? 'কখনো নয়' : DateUtilsX.pretty(lastSync)),
              const SizedBox(height: 6),
              if (_content.isConfigured)
                Text(
                  _content.manifestUrl,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11.5, height: 1.5),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editUrl,
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: Text(_content.isConfigured ? 'URL বদলাও' : 'রিপো URL বসাও'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _syncing ? null : _sync,
                      icon: _syncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(_syncing ? 'সিংক…' : 'সিংক'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _card(
            title: 'অধ্যয়ন',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined,
                    color: AppColors.accent),
                title: const Text('দৈনিক পড়ার লক্ষ্য'),
                subtitle: Text('${_progress.dailyGoalMinutes} মিনিট'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _setGoal,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _card(
            title: 'রিমাইন্ডার',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_active_outlined,
                    color: AppColors.purple),
                title: const Text('দৈনিক রিভিশন রিমাইন্ডার'),
                subtitle: Text(_reminderEnabled
                    ? 'প্রতিদিন ${_reminderTime.format(context)}-এ জানানো হবে'
                    : 'বন্ধ আছে'),
                value: _reminderEnabled,
                onChanged: _toggleReminder,
              ),
              if (_reminderEnabled) ...[
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded,
                      color: AppColors.accent),
                  title: const Text('রিমাইন্ডারের সময়'),
                  trailing: Text(
                    _reminderTime.format(context),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onTap: _pickReminderTime,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _card(
            title: 'ডেটা',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.download_rounded,
                    color: AppColors.accent),
                title: const Text('ডাউনলোড ম্যানেজার'),
                subtitle: const Text('অফলাইনে সংরক্ষিত বই ও স্টোরেজ'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DownloadManagerScreen(),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.backup_outlined,
                    color: AppColors.info),
                title: const Text('ব্যাকআপ ও পুনরুদ্ধার'),
                subtitle: const Text('অগ্রগতি, নোট ও বুকমার্ক সংরক্ষণ করো'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BackupScreen(),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cleaning_services_outlined,
                    color: AppColors.warning),
                title: const Text('কনটেন্ট ক্যাশ রিসেট'),
                subtitle: const Text('অগ্রগতি ও নোট অক্ষত থাকবে'),
                onTap: _resetCache,
              ),
              const Divider(),
              const Text(
                'ব্যক্তিগত নোট বা অগ্রগতি কখনো public repository-তে আপলোড করবে না। ফোন বদলালে উপরের "ব্যাকআপ ও পুনরুদ্ধার" ব্যবহার করো।',
                style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _card(
            title: 'অ্যাপ সম্পর্কে',
            children: [
              _row('অ্যাপ', AppConstants.appName),
              _row('স্কিমা ভার্সন', '1'),
              _row('ধরন', 'Offline-first'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
}
