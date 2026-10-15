import '../models/reading_progress.dart';
import '../models/weak_word.dart';

class ProgressService {
  static final ProgressService instance = ProgressService._();
  ProgressService._();

  ReadingProgress? get currentProgress => null;
  List<WeakWord> get weakWords => [];
  Future<void> saveProgress(ReadingProgress progress) async {}
  Future<void> addWeakWord(WeakWord word) async {}
}
