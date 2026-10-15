import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/book.dart';
import '../../data/repositories/library_repository.dart';

/// In-app reader for PDF books. Works from a downloaded local file when
/// available, otherwise streams from the book's network file URL.
class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key, required this.book, this.localPath});

  final Book book;
  final String? localPath;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final _controller = PdfViewerController();
  final _library = LibraryRepository.instance;

  int _currentPage = 1;
  int _pageCount = 0;

  @override
  void initState() {
    super.initState();
    final saved = _library.get(widget.book.id).lastPage;
    _currentPage = saved < 1 ? 1 : saved;
  }

  bool get _hasLocal =>
      widget.localPath != null && File(widget.localPath!).existsSync();

  bool get _hasNetwork =>
      widget.book.fileUrl.startsWith('http') &&
      widget.book.fileUrl.toLowerCase().endsWith('.pdf');

  Future<void> _toggleBookmark() async {
    await _library.toggleBookmark(widget.book.id, _currentPage);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('পৃষ্ঠা $_currentPage বুকমার্ক করা হয়েছে')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLocal && !_hasNetwork) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'এই বইয়ের কোনো PDF ফাইল বা লিংক যোগ করা হয়নি।\nবইয়ের বিবরণে বৈধ লিংক যোগ করো বা ডাউনলোড করো।',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, height: 1.6),
            ),
          ),
        ),
      );
    }

    final bookmarks = _library.get(widget.book.id).bookmarks;
    final isBookmarked = bookmarks.contains(_currentPage);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (_pageCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('$_currentPage / $_pageCount',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white60)),
              ),
            ),
          IconButton(
            tooltip: 'বুকমার্ক',
            onPressed: _toggleBookmark,
            icon: Icon(
              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isBookmarked ? AppColors.warning : null,
            ),
          ),
        ],
      ),
      body: _hasLocal
          ? PdfViewer.file(
              widget.localPath!,
              controller: _controller,
              initialPageNumber: _currentPage,
              params: _params,
            )
          : PdfViewer.uri(
              Uri.parse(widget.book.fileUrl),
              controller: _controller,
              initialPageNumber: _currentPage,
              params: _params,
              headers: _networkHeaders(widget.book.fileUrl),
            ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        child: Row(
          children: [
            IconButton(
              tooltip: 'পূর্ববর্তী পৃষ্ঠা',
              onPressed: _currentPage > 1
                  ? () => _controller.goToPage(pageNumber: _currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'পরবর্তী পৃষ্ঠা',
              onPressed: (_pageCount == 0 || _currentPage < _pageCount)
                  ? () => _controller.goToPage(pageNumber: _currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'ছোট করো',
              onPressed: () => _controller.zoomDown(),
              icon: const Icon(Icons.zoom_out_rounded),
            ),
            IconButton(
              tooltip: 'বড় করো',
              onPressed: () => _controller.zoomUp(),
              icon: const Icon(Icons.zoom_in_rounded),
            ),
          ],
        ),
      ),
    );
  }

  static Map<String, String> _networkHeaders(String url) {
    final origin = Uri.tryParse(url)?.origin ?? '';
    return {
      'User-Agent': AppConstants.browserUserAgent,
      'Accept': 'application/pdf,application/octet-stream,*/*',
      if (origin.isNotEmpty) 'Referer': '$origin/',
    };
  }

  PdfViewerParams get _params => PdfViewerParams(
        margin: 8,
        backgroundColor: AppColors.scaffold,
        onViewerReady: (document, controller) {
          if (mounted) {
            setState(() => _pageCount = document.pages.length);
            _library.setLastPage(widget.book.id, _currentPage);
          }
        },
        onPageChanged: (pageNumber) {
          if (pageNumber == null || !mounted) return;
          setState(() => _currentPage = pageNumber);
          _library.setLastPage(widget.book.id, pageNumber);
        },
      );
}
