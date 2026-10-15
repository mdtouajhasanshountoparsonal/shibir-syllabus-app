import '../../core/constants/app_constants.dart';
import '../models/content_manifest.dart';
import '../sources/local_content_source.dart';
import '../../services/local_store.dart';
import '../../services/sync_service.dart';

/// Provides the current content bundle and handles syncing.
///
/// Offline-first strategy: prefer the last successfully synced cache, and fall
/// back to the bundled assets that always ship with the app.
class ContentRepository {
  ContentRepository._();

  static final ContentRepository instance = ContentRepository._();

  final LocalContentSource _local = const LocalContentSource();
  final LocalStore _store = LocalStore.instance;
  late final SyncService _sync = SyncService();

  /// Loads content without touching the network.
  Future<ContentBundle> load() async {
    final cache = _store.readContentCache();
    final version = cache['version'] ?? '';
    final cached = _local.bundleFromCache(
      stages: cache['stages'],
      books: cache['books'],
      memorization: cache['memorization'],
      quizzes: cache['quizzes'],
      schedule: cache['schedule'],
      programs: cache['programs'],
      version: version,
    );
    if (cached != null && !cached.isEmpty) return cached;
    return _local.loadBundled();
  }

  Future<SyncResult> sync({bool force = false}) => _sync.sync(force: force);

  bool get isConfigured => _sync.isConfigured;

  String get manifestUrl => _sync.manifestUrl;

  Future<void> setManifestUrl(String url) =>
      _store.setSetting(PrefKeys.manifestUrl, url.trim());

  Future<void> clearManifestUrl() async {
    await _store.setSetting(PrefKeys.manifestUrl, '');
    await _store.clearContentCache();
  }

  String get cachedVersion => _sync.cachedVersion;

  DateTime? get lastSyncAt {
    final raw = _store.getSetting<String>(PrefKeys.lastSyncAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }
}
