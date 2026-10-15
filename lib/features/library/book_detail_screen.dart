import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/book.dart';
import '../../data/models/progress.dart';
import '../../data/repositories/library_repository.dart';
import '../../services/download_service.dart';
import '../../shared/widgets/section_header.dart';
import '../reader/pdf_reader_screen.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.book});
  final Book book;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _library = LibraryRepository.instance;
  late BookProgress _progress;
  bool _downloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _progress = _library.get(widget.book.id);
  }

  void _refresh() => setState(() => _progress = _library.get(widget.book.id));

  String get _primaryUrl {
    final book = widget.book;
    if (book.externalUrl.isNotEmpty) return book.externalUrl;
    return book.fileUrl;
  }

  Future<void> _openLink() async {
    final url = _primaryUrl;
    if (url.isEmpty) {
      _snack('এই বইয়ের কোনো বৈধ লিংক যোগ করা হয়নি।');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _snack('লিংক খোলা যায়নি: $url');
    }
  }

  bool get _canReadInApp {
    final book = widget.book;
    final hasLocal = _progress.localPath.isNotEmpty &&
        _progress.downloaded;
    final hasNetworkPdf = book.fileUrl.startsWith('http') &&
        book.fileUrl.toLowerCase().endsWith('.pdf');
    return hasLocal || hasNetworkPdf;
  }

  void _openReader() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfReaderScreen(
          book: widget.book,
          localPath: _progress.downloaded ? _progress.localPath : null,
        ),
      ),
    );
  }

  Future<void> _toggleDownload() async {
    final book = widget.book;
    if (_progress.downloaded) {
      if (_progress.localPath.isNotEmpty) {
        await DownloadService.instance.delete(_progress.localPath);
      }
      await _library.setDownloaded(book.id, downloaded: false);
      _refresh();
      return;
    }

    if (book.fileUrl.isEmpty || !DownloadService.isHttpUrl(book.fileUrl)) {
      _snack('ডাউনলোডের জন্য বৈধ ফাইল লিংক নেই। বাহ্যিক লিংক ব্যবহার করো।');
      return;
    }

    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });
    try {
      final path = await DownloadService.instance.download(
        bookId: book.id,
        url: book.fileUrl,
        onProgress: (p) => setState(() => _downloadProgress = p),
      );
      await _library.setDownloaded(book.id, downloaded: true, localPath: path);
      if (mounted) _snack('বই অফলাইনে সংরক্ষণ হয়েছে।');
    } catch (e) {
      if (mounted) _snack('ডাউনলোড ব্যর্থ: $e');
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
        _refresh();
      }
    }
  }

  Future<void> _changePage(int delta) async {
    final maxPage = widget.book.pages > 0 ? widget.book.pages : 9999;
    final next = (_progress.lastPage + delta).clamp(0, maxPage);
    await _library.setLastPage(widget.book.id, next);
    _refresh();
  }

  Future<void> _toggleBookmark() async {
    await _library.toggleBookmark(widget.book.id, _progress.lastPage);
    _refresh();
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('নোট যোগ করো'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'তোমার নোট লিখো…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    await _library.addNote(widget.book.id, text, page: _progress.lastPage);
    _refresh();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return Scaffold(
      appBar: AppBar(title: const Text('বইয়ের বিবরণ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _Header(book: book),
          const SizedBox(height: 16),
          if (_canReadInApp) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openReader,
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: const Text('বই পড়ো'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openLink,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('লিংক খুলো'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _downloading ? null : _toggleDownload,
                  icon: _downloading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: _downloadProgress == 0
                                ? null
                                : _downloadProgress,
                          ),
                        )
                      : Icon(
                          _progress.downloaded
                              ? Icons.delete_outline_rounded
                              : Icons.download_rounded,
                          size: 18,
                        ),
                  label: Text(_progress.downloaded ? 'মুছে ফেলো' : 'ডাউনলোড'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'পড়ার অগ্রগতি'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('শেষ পড়া পৃষ্ঠা',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _changePage(-1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${_progress.lastPage}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                          IconButton(
                            onPressed: () => _changePage(1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Icon(
                        _progress.bookmarks.contains(_progress.lastPage)
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _progress.bookmarks.isEmpty
                              ? 'কোনো বুকমার্ক নেই'
                              : 'বুকমার্ক: ${_progress.bookmarks.join(', ')}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12.5),
                        ),
                      ),
                      TextButton(
                        onPressed: _toggleBookmark,
                        child: Text(
                          _progress.bookmarks.contains(_progress.lastPage)
                              ? 'সরাও'
                              : 'বুকমার্ক করো',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (book.chapters.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'অধ্যায়'),
            const SizedBox(height: 10),
            ...book.chapters.map(
              (chapter) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.list_alt_rounded,
                      color: AppColors.accent),
                  title: Text(chapter.title),
                  subtitle: chapter.pageLabel.isEmpty
                      ? null
                      : Text(chapter.pageLabel),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SectionHeader(
            title: 'আমার নোট (${_progress.notes.length})',
            actionLabel: 'যোগ করো',
            onAction: _addNote,
          ),
          const SizedBox(height: 10),
          if (_progress.notes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('এখনো কোনো নোট নেই। পড়ার সময় নোট যোগ করো।',
                    style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            ..._progress.notes.map(
              (note) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.sticky_note_2_outlined,
                      color: AppColors.info),
                  title: Text(note.text),
                  subtitle: note.page > 0 ? Text('পৃষ্ঠা ${note.page}') : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () async {
                      await _library.deleteNote(book.id, note.id);
                      _refresh();
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7F1830), Color(0xFF25131D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white70),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(book.author.isEmpty ? 'লেখক অজানা' : book.author,
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tag(book.format.labelBn),
                        if (book.language.isNotEmpty) _tag(book.language),
                        if (book.edition.isNotEmpty) _tag(book.edition),
                        if (book.pages > 0) _tag('${book.pages} পৃষ্ঠা'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (book.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(book.description,
                style: const TextStyle(
                    height: 1.6, color: Colors.white70, fontSize: 13)),
          ],
          if (book.publisher.isNotEmpty || book.source.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 6),
            if (book.publisher.isNotEmpty)
              _metaRow('প্রকাশক', book.publisher),
            if (book.source.isNotEmpty) _metaRow('উৎস', book.source),
          ],
        ],
      ),
    );
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      );

  Widget _metaRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(label,
                  style: const TextStyle(color: Colors.white38, fontSize: 12.5)),
            ),
            Expanded(
              child: Text(value,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12.5)),
            ),
          ],
        ),
      );
}
