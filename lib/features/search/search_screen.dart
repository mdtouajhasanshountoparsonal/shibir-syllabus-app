import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/content_manifest.dart';
import '../../services/local_store.dart';
import '../../services/search_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../library/book_detail_screen.dart';
import '../memorization/memorization_screen.dart';
import '../syllabus/item_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.bundle});
  final ContentBundle bundle;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _store = LocalStore.instance;

  List<SearchHit> _hits = const [];
  List<String> _recent = const [];
  bool _searched = false;
  SearchKind? _filter;

  @override
  void initState() {
    super.initState();
    _recent = _store.getRecentSearches();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run(String value) {
    final trimmed = value.trim();
    setState(() {
      _hits = SearchService.search(widget.bundle, trimmed);
      _searched = trimmed.isNotEmpty;
    });
  }

  Future<void> _commit() async {
    if (_controller.text.trim().isEmpty) return;
    final updated = await _store.addRecentSearch(_controller.text);
    if (mounted) setState(() => _recent = updated);
  }

  void _useRecent(String query) {
    _controller.text = query;
    _controller.selection =
        TextSelection.collapsed(offset: query.length);
    _run(query);
  }

  List<SearchHit> get _visibleHits => _filter == null
      ? _hits
      : _hits.where((h) => h.kind == _filter).toList();

  void _open(SearchHit hit) {
    switch (hit.kind) {
      case SearchKind.stageItem:
        if (hit.item != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(
                item: hit.item!,
                stageId: hit.stageId,
              ),
            ),
          );
        }
        break;
      case SearchKind.book:
        if (hit.book != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookDetailScreen(book: hit.book!),
            ),
          );
        }
        break;
      case SearchKind.memorization:
        if (hit.memorization != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  MemorizationPracticeScreen(item: hit.memorization!),
            ),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('খোঁজো')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
            child: TextField(
              controller: _controller,
              onChanged: _run,
              onSubmitted: (_) => _commit(),
              textInputAction: TextInputAction.search,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'পাঠ, বই বা মুখস্থ আইটেম খোঁজো',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          _run('');
                        },
                      ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_searched) _buildFilterChips(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = <(SearchKind?, String)>[
      (null, 'সব (${_hits.length})'),
      (SearchKind.stageItem,
          'পাঠ (${_hits.where((h) => h.kind == SearchKind.stageItem).length})'),
      (SearchKind.book,
          'বই (${_hits.where((h) => h.kind == SearchKind.book).length})'),
      (SearchKind.memorization,
          'মুখস্থ (${_hits.where((h) => h.kind == SearchKind.memorization).length})'),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          for (final (kind, label) in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: _filter == kind,
                showCheckmark: false,
                selectedColor: AppColors.seed.withValues(alpha: 0.30),
                onSelected: (_) => setState(() => _filter = kind),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (!_searched) {
      return _buildRecent();
    }
    final hits = _visibleHits;
    if (hits.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'কিছু পাওয়া যায়নি',
        message: 'অন্য শব্দ দিয়ে আবার চেষ্টা করো।',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      itemCount: hits.length,
      itemBuilder: (context, index) {
        final hit = hits[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(_iconFor(hit.kind), color: AppColors.accent),
            title: Text(hit.title),
            subtitle: Text(hit.subtitle),
            trailing:
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            onTap: () {
              _commit();
              _open(hit);
            },
          ),
        );
      },
    );
  }

  Widget _buildRecent() {
    if (_recent.isEmpty) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'কিছু খোঁজো',
        message: 'সিলেবাসের পাঠ, লাইব্রেরির বই ও মুখস্থ আইটেম একসাথে খোঁজা যাবে।',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('সাম্প্রতিক খোঁজ',
                style: TextStyle(fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () async {
                await _store.clearRecentSearches();
                if (mounted) setState(() => _recent = const []);
              },
              child: const Text('মুছে ফেলো'),
            ),
          ],
        ),
        ..._recent.map(
          (query) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history_rounded, color: Colors.white38),
            title: Text(query),
            trailing: const Icon(Icons.north_west_rounded,
                size: 16, color: Colors.white38),
            onTap: () => _useRecent(query),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(SearchKind kind) {
    switch (kind) {
      case SearchKind.stageItem:
        return Icons.account_tree_rounded;
      case SearchKind.book:
        return Icons.menu_book_rounded;
      case SearchKind.memorization:
        return Icons.psychology_rounded;
    }
  }
}
