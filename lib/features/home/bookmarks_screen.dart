import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/book.dart';
import '../../data/models/content_manifest.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../library/book_detail_screen.dart';

/// Shows every book that has at least one bookmark, with the marked pages.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key, this.bundle});
  final ContentBundle? bundle;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  ContentBundle? _bundle;

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

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    if (bundle == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final library = LibraryRepository.instance;
    final entries = <MapEntry<Book, List<int>>>[];
    for (final book in bundle.books) {
      final bookmarks = library.get(book.id).bookmarks;
      if (bookmarks.isNotEmpty) {
        entries.add(MapEntry(book, bookmarks));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('বুকমার্ক করা অধ্যায়')),
      body: entries.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'কোনো বুকমার্ক নেই',
              message: 'বই পড়ার সময় পৃষ্ঠা বুকমার্ক করলে এখানে জমা হবে।',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.bookmark_rounded,
                        color: AppColors.warning),
                    title: Text(entry.key.title),
                    subtitle: Text('পৃষ্ঠা: ${entry.value.join(', ')}'),
                    trailing:
                        const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookDetailScreen(book: entry.key),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
