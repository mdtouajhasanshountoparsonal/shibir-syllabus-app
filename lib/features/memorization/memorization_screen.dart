import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/content_manifest.dart';
import '../../data/models/memorization.dart';
import '../../data/models/progress.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/memorization_repository.dart';
import '../../services/audio_cache_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/audio_recitation_player.dart';

const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

String bnNumber(int value) {
  final buffer = StringBuffer();
  for (final ch in value.toString().split('')) {
    final digit = int.tryParse(ch);
    buffer.write(digit == null ? ch : _bnDigits[digit]);
  }
  return buffer.toString();
}

class MemorizationScreen extends StatefulWidget {
  const MemorizationScreen({super.key, this.bundle});
  final ContentBundle? bundle;

  @override
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends State<MemorizationScreen> {
  ContentBundle? _bundle;
  final _memo = MemorizationRepository.instance;

  @override
  void initState() {
    super.initState();
    if (widget.bundle != null) {
      _bundle = widget.bundle;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final bundle = await ContentRepository.instance.load();
    if (!mounted) return;
    setState(() => _bundle = bundle);
  }

  void _refresh() => setState(() {});

  Future<void> _openPractice(MemorizationItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemorizationPracticeScreen(item: item),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('মুখস্থ ও অনুশীলন',
              style: TextStyle(fontWeight: FontWeight.w800)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'আজকের রিভিশন'),
              Tab(text: 'সব'),
              Tab(text: 'নতুন'),
            ],
          ),
        ),
        body: bundle == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildList(
                    _memo.dueItems(bundle.memorizationItems),
                    emptyTitle: 'আজ কোনো রিভিশন বাকি নেই',
                    emptyMessage: 'চমৎকার! পরবর্তী রিভিশনের তারিখ এলে এখানে দেখা যাবে।',
                  ),
                  _buildList(
                    bundle.memorizationItems,
                    emptyTitle: 'কোনো মুখস্থ আইটেম নেই',
                    emptyMessage: 'GitHub-এর memorization.json ফাইলে আইটেম যোগ করো।',
                  ),
                  _buildList(
                    _memo.newItems(bundle.memorizationItems),
                    emptyTitle: 'নতুন কোনো আইটেম নেই',
                    emptyMessage: 'সব আইটেমই একবার শুরু করা হয়েছে।',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildList(
    List<MemorizationItem> items, {
    required String emptyTitle,
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.psychology_outlined,
        title: emptyTitle,
        message: emptyMessage,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final progress = _memo.get(item.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _MemoCard(
            item: item,
            progress: progress,
            onTap: () => _openPractice(item),
          ),
        );
      },
    );
  }
}

class _MemoCard extends StatelessWidget {
  const _MemoCard({
    required this.item,
    required this.progress,
    required this.onTap,
  });

  final MemorizationItem item;
  final MemorizationProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final due = progress.isDue(DateTime.now());
    final previewArabic = item.hasAyahs ? item.ayahs.first.arabic : item.arabic;
    final previewMeaning = item.hasAyahs ? item.ayahs.first.meaning : item.meaning;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_rounded,
                      color: AppColors.purple, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  if (item.hasAyahs)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text('${bnNumber(item.ayahs.length)} আয়াত',
                          style: const TextStyle(
                              fontSize: 10.5, color: Colors.white38)),
                    ),
                  if (due)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('আজ',
                          style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              if (previewArabic.isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    previewArabic,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 19, height: 1.9, color: Colors.white),
                  ),
                ),
              ],
              if (previewMeaning.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(previewMeaning,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12.5, height: 1.5)),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(progress.status.labelBn,
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (progress.nextReview != null)
                    Text('পরবর্তী: ${DateUtilsX.relativeBn(progress.nextReview!)}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white38)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen practice view.
///
/// Multi-ayah entries render one logical card per ayah and play the ayahs as a
/// continuous playlist, highlighting the ayah that is currently being recited.
class MemorizationPracticeScreen extends StatefulWidget {
  const MemorizationPracticeScreen({super.key, required this.item});
  final MemorizationItem item;

  @override
  State<MemorizationPracticeScreen> createState() =>
      _MemorizationPracticeScreenState();
}

class _MemorizationPracticeScreenState
    extends State<MemorizationPracticeScreen> {
  final _memo = MemorizationRepository.instance;
  final _playerKey = GlobalKey<AudioRecitationPlayerState>();
  bool _showMeaning = false;

  /// Player-playlist indices of the ayahs that actually have audio.
  late final List<int> _playableAyahIndices;

  /// Remote audio URLs, used until each one has been cached locally.
  late final List<String> _remoteSources;

  /// Resolved sources: local file path when cached, else the remote URL.
  late List<String> _sources;

  /// Offline download progress, 0..1. Null until downloading starts.
  double? _downloadProgress;
  int _downloadedCount = 0;
  bool _downloadFailed = false;

  /// Resolved (downloaded) source for flat, single-audio items.
  late final Future<String> _flatSource;

  late final List<GlobalKey> _cardKeys;

  StreamSubscription<Duration>? _positionSub;
  int _activePlayerIndex = 0;
  int _activeWord = -1;

  @override
  void initState() {
    super.initState();
    final ayahs = widget.item.ayahs;
    _playableAyahIndices = [];
    _remoteSources = [];
    for (var i = 0; i < ayahs.length; i++) {
      if (ayahs[i].audioUrl.isNotEmpty) {
        _playableAyahIndices.add(i);
        _remoteSources.add(ayahs[i].audioUrl);
      }
    }
    _sources = List<String>.from(_remoteSources);
    _flatSource = _resolveFlatSource();
    _cardKeys = List.generate(ayahs.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachPosition();
      _prepareOfflineAudio();
    });
  }

  /// Resolves a flat item's single audio file to a local path when possible.
  Future<String> _resolveFlatSource() async {
    final url = widget.item.audioUrl;
    if (url.isEmpty) return '';
    try {
      return await AudioCacheService.instance.ensure(url);
    } catch (_) {
      return url;
    }
  }

  /// Downloads every recitation file so playback works without internet.
  ///
  /// Sources are swapped once, after the last file settles, so playback that
  /// is already in progress is not interrupted by a stream of reloads.
  Future<void> _prepareOfflineAudio() async {
    if (_remoteSources.isEmpty) return;
    setState(() {
      _downloadProgress = 0;
      _downloadedCount = 0;
      _downloadFailed = false;
    });

    final resolved = List<String?>.filled(_remoteSources.length, null);
    var done = 0;
    for (var i = 0; i < _remoteSources.length; i++) {
      try {
        resolved[i] = await AudioCacheService.instance.ensure(
          _remoteSources[i],
          onProgress: (p) {
            if (!mounted) return;
            setState(() =>
                _downloadProgress = (done + p) / _remoteSources.length);
          },
        );
      } catch (_) {
        // Leave null so this ayah falls back to the network source.
      }
      done++;
      if (!mounted) return;
      setState(() {
        if (resolved[i] != null) _downloadedCount++;
        _downloadProgress = done / _remoteSources.length;
      });
    }

    if (!mounted) return;
    final sources = <String>[
      for (var i = 0; i < _remoteSources.length; i++)
        resolved[i] ?? _remoteSources[i],
    ];
    setState(() {
      _sources = sources;
      _downloadFailed = resolved.any((r) => r == null);
      _downloadProgress = null;
    });
  }

  void _attachPosition() {
    if (!mounted) return;
    final state = _playerKey.currentState;
    if (state == null) return;
    _positionSub = state.positionStream.listen(_onPosition);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  int get _activeAyahIndex {
    if (_playableAyahIndices.isEmpty) return -1;
    final clamped =
        _activePlayerIndex.clamp(0, _playableAyahIndices.length - 1);
    return _playableAyahIndices[clamped];
  }

  void _onIndexChanged(int index) {
    setState(() {
      _activePlayerIndex = index;
      _activeWord = -1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
  }

  void _onPosition(Duration position) {
    final state = _playerKey.currentState;
    if (state == null) return;
    final index = state.currentIndex;
    if (index == null || index >= _playableAyahIndices.length) return;
    final ayah = widget.item.ayahs[_playableAyahIndices[index]];
    if (!ayah.hasWords) {
      if (_activeWord != -1) setState(() => _activeWord = -1);
      return;
    }
    final within = position.inMilliseconds;
    final word = ayah.wordIndexAt(within);
    if (word != _activeWord) setState(() => _activeWord = word);
  }

  void _scrollToActive() {
    final index = _activeAyahIndex;
    if (index < 0 || index >= _cardKeys.length) return;
    final ctx = _cardKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.25,
    );
  }

  void _playAyah(int ayahIndex) {
    final playerIndex = _playableAyahIndices.indexOf(ayahIndex);
    if (playerIndex < 0) return;
    setState(() {
      _activePlayerIndex = playerIndex;
      _activeWord = -1;
    });
    _playerKey.currentState?.playAt(playerIndex);
  }

  Widget _offlineStatus() {
    final total = _remoteSources.length;
    if (_downloadProgress != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(strokeWidth: 1.6),
              ),
              const SizedBox(width: 8),
              Text(
                'অফলাইনে সংরক্ষণ হচ্ছে… $_downloadedCount/$total',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _downloadProgress,
              minHeight: 3,
              backgroundColor: AppColors.border,
              color: AppColors.accent,
            ),
          ),
        ],
      );
    }
    if (_downloadFailed) {
      return Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 13, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'কিছু অডিও অফলাইনে সংরক্ষিত হয়নি — ইন্টারনেট থাকলে আবার চেষ্টা হবে।',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Icon(Icons.offline_pin_rounded, size: 13, color: AppColors.success),
        const SizedBox(width: 6),
        Text(
          'অফলাইনে শোনার জন্য প্রস্তুত ($total অডিও)',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _markMemorized() async {
    await _memo.markMemorized(widget.item.id);
    if (!mounted) return;
    final next = _memo.get(widget.item.id).nextReview;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next == null
              ? 'মুখস্থ হিসেবে চিহ্নিত হয়েছে।'
              : 'মুখস্থ হয়েছে! পরবর্তী রিভিশন: ${DateUtilsX.relativeBn(next)}',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _markNeedsPractice() async {
    await _memo.markNeedsPractice(widget.item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('কাল আবার অনুশীলনের তালিকায় যোগ হয়েছে।')),
    );
    setState(() {});
  }

  Widget _assessment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'আত্মমূল্যায়ন'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _markNeedsPractice,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('আরও অনুশীলন'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _markMemorized,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('মুখস্থ হয়েছে'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'রিভিশন সূচি: ${MemorizationProgress.kReviewIntervals.join(' → ')} দিন',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item.hasAyahs) return _buildAyahView(item);
    return _buildFlatView(item);
  }

  Widget _buildAyahView(MemorizationItem item) {
    final activeAyah = _activeAyahIndex;
    return Scaffold(
      appBar: AppBar(title: const Text('মুখস্থ অনুশীলন')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(item.reference,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12.5)),
                ),
                Text('${bnNumber(item.ayahs.length)} আয়াত',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11.5)),
              ],
            ),
          ),
          if (_remoteSources.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: _offlineStatus(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
              child: AudioRecitationPlayer(
                key: _playerKey,
                sources: _sources,
                onIndexChanged: _onIndexChanged,
              ),
            ),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              itemCount: item.ayahs.length + 1,
              itemBuilder: (context, index) {
                if (index == item.ayahs.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: _assessment(),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AyahCard(
                    key: _cardKeys[index],
                    ayah: item.ayahs[index],
                    active: index == activeAyah,
                    activeWord: index == activeAyah ? _activeWord : -1,
                    onPlay: item.ayahs[index].audioUrl.isEmpty
                        ? null
                        : () => _playAyah(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatView(MemorizationItem item) {
    return Scaffold(
      appBar: AppBar(title: const Text('মুখস্থ অনুশীলন')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          if (item.reference.isNotEmpty)
            Text(item.reference,
                style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                if (item.arabic.isNotEmpty)
                  Text(
                    item.arabic,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 26, height: 2.1, color: Colors.white),
                  ),
                if (item.transliteration.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(item.transliteration,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.info, fontSize: 13.5, height: 1.6)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (item.audioUrl.isNotEmpty) ...[
            FutureBuilder<String>(
              future: _flatSource,
              builder: (context, snap) {
                final source = snap.data;
                if (source == null || source.isEmpty) {
                  return const SizedBox.shrink();
                }
                return AudioRecitationPlayer(sources: [source]);
              },
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: () => setState(() => _showMeaning = !_showMeaning),
            icon: Icon(
              _showMeaning
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            label: Text(_showMeaning ? 'অর্থ লুকাও' : 'অর্থ দেখো'),
          ),
          if (_showMeaning && item.meaning.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(item.meaning,
                    style: const TextStyle(height: 1.7, fontSize: 14)),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _assessment(),
        ],
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({
    super.key,
    required this.ayah,
    required this.active,
    this.activeWord = -1,
    this.onPlay,
  });

  final MemoAyah ayah;
  final bool active;

  /// Index of the word currently being recited (-1 when none).
  final int activeWord;
  final VoidCallback? onPlay;

  Widget _arabic() {
    if (!ayah.hasWords) {
      return Text(
        ayah.arabic,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 25, height: 2.1, color: Colors.white),
      );
    }
    final spans = <TextSpan>[];
    for (var i = 0; i < ayah.words.length; i++) {
      final highlighted = active && i == activeWord;
      spans.add(TextSpan(
        text: i == ayah.words.length - 1 ? ayah.words[i].arabic : '${ayah.words[i].arabic} ',
        style: TextStyle(
          color: Colors.white,
          backgroundColor: highlighted
              ? AppColors.accent.withValues(alpha: 0.45)
              : Colors.transparent,
        ),
      ));
    }
    return RichText(
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: const TextStyle(fontSize: 25, height: 2.1, color: Colors.white),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: active
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AppColors.accent : AppColors.border,
          width: active ? 1.6 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: (active ? AppColors.accent : Colors.white24)
                      .withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'আয়াত ${bnNumber(ayah.numberInSurah)}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.accent : Colors.white54,
                  ),
                ),
              ),
              const Spacer(),
              if (onPlay != null)
                InkWell(
                  onTap: onPlay,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      active
                          ? Icons.graphic_eq_rounded
                          : Icons.play_arrow_rounded,
                      size: 22,
                      color: active ? AppColors.accent : Colors.white38,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (ayah.arabic.isNotEmpty) _arabic(),
          if (ayah.pronunciation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              ayah.pronunciation,
              style: const TextStyle(
                  color: AppColors.info, fontSize: 14, height: 1.7),
            ),
          ],
          if (ayah.meaning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ayah.meaning,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13.5, height: 1.7),
            ),
          ],
        ],
      ),
    );
  }
}
