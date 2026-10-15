import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/book.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../services/download_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../reader/pdf_reader_screen.dart';

/// Lists offline-downloaded books and lets the user open or remove them.
class DownloadManagerScreen extends StatefulWidget {
  const DownloadManagerScreen({super.key});

  @override
  State<DownloadManagerScreen> createState() => _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends State<DownloadManagerScreen> {
  final _library = LibraryRepository.instance;
  List<Book> _books = const [];
  Map<String, int> _sizes = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bundle = await ContentRepository.instance.load();
    final downloaded = _library.downloadedBooks();
    final byId = {for (final b in bundle.books) b.id: b};
    final books = <Book>[];
    final sizes = <String, int>{};

    for (final p in downloaded) {
      final book = byId[p.bookId];
      if (book != null) books.add(book);
      final file = File(p.localPath);
      if (p.localPath.isNotEmpty && await file.exists()) {
        sizes[p.bookId] = await file.length();
      }
    }
    if (!mounted) return;
    setState(() {
      _books = books;
      _sizes = sizes;
      _loading = false;
    });
  }

  Future<void> _delete(Book book) async {
    final progress = _library.get(book.id);
    if (progress.localPath.isNotEmpty) {
      await DownloadService.instance.delete(progress.localPath);
    }
    await _library.setDownloaded(book.id, downloaded: false);
    _load();
  }

  int get _totalBytes => _sizes.values.fold(0, (a, b) => a + b);

  String _formatSize(int bytes) {
    if (bytes <= 0) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ডাউনলোড ম্যানেজার')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? const EmptyState(
                  icon: Icons.download_outlined,
                  title: 'কোনো ডাউনলোড নেই',
                  message: 'বইয়ের পৃষ্ঠায় গিয়ে "ডাউনলোড" চাপলে অফলাইনে সংরক্ষিত হবে।',
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sd_storage_rounded,
                              color: AppColors.accent),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_books.length}টি বই সংরক্ষিত',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text('মোট ${_formatSize(_totalBytes)}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
                        itemCount: _books.length,
                        itemBuilder: (context, index) {
                          final book = _books[index];
                          final progress = _library.get(book.id);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const Icon(Icons.picture_as_pdf_rounded,
                                  color: AppColors.danger),
                              title: Text(book.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                '${_sizes[book.id] == null ? '—' : _formatSize(_sizes[book.id]!)} • পৃষ্ঠা ${progress.lastPage}',
                              ),
                              trailing: IconButton(
                                tooltip: 'মুছে ফেলো',
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.warning),
                                onPressed: () => _delete(book),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PdfReaderScreen(
                                    book: book,
                                    localPath: progress.localPath,
                                  ),
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
}
