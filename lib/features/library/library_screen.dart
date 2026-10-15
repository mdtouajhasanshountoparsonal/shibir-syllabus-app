import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/book.dart';
import '../../data/models/content_manifest.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../shared/widgets/empty_state.dart';
import 'book_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.initialBundle});
  final ContentBundle? initialBundle;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  ContentBundle? _bundle;
  final _searchController = TextEditingController();
  String _query = '';
  String _stageFilter = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.initialBundle != null) {
      _bundle = widget.initialBundle;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final bundle = await ContentRepository.instance.load();
    if (!mounted) return;
    setState(() => _bundle = bundle);
  }

  List<Book> get _filtered {
    final books = _bundle?.books ?? const <Book>[];
    return books.where((b) {
      final matchesStage = _stageFilter == 'all' || b.stage == _stageFilter;
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.category.toLowerCase().contains(q);
      return matchesStage && matchesQuery;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ডিজিটাল লাইব্রেরি',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: bundle == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'বই, লেখক বা বিষয় খোঁজো',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    children: [
                      _filterChip('all', 'সব'),
                      ...bundle.stages.map(
                        (s) => _filterChip(s.id, s.title),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _filtered.isEmpty
                      ? const EmptyState(
                          icon: Icons.local_library_outlined,
                          title: 'কোনো বই পাওয়া যায়নি',
                          message:
                              'GitHub-এর books.json ফাইলে বই যোগ করলে এখানে দেখা যাবে।',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final book = _filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _BookCard(
                                book: book,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BookDetailScreen(book: book),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _stageFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _stageFilter = value),
        selectedColor: AppColors.seed.withValues(alpha: 0.3),
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.white60,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onTap});
  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = LibraryRepository.instance.get(book.id);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7F1830), Color(0xFF25131D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white70),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.5)),
                    const SizedBox(height: 3),
                    Text(
                      book.author.isEmpty ? 'লেখক অজানা' : book.author,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12.5),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _miniChip(book.format.labelBn),
                        const SizedBox(width: 6),
                        if (book.pages > 0) _miniChip('${book.pages} পৃষ্ঠা'),
                        if (progress.downloaded) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.download_done_rounded,
                              size: 14, color: AppColors.success),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 10.5, color: Colors.white60)),
      );
}

