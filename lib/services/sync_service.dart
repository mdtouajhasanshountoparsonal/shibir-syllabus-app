import '../core/constants/app_constants.dart';
import '../data/sources/github_content_source.dart';
import 'local_store.dart';

enum SyncStatus { updated, upToDate, notConfigured, failed }

class SyncResult {
  const SyncResult({
    required this.status,
    required this.message,
    this.version = '',
  });

  final SyncStatus status;
  final String message;
  final String version;

  bool get isSuccess => status != SyncStatus.failed;
}

/// Checks GitHub for newer content and persists it locally.
///
/// Safety rules:
///  * a failed download never deletes the previous cache;
///  * the new payload is validated before it replaces the old one;
///  * the same content version is not re-downloaded.
class SyncService {
  SyncService({
    GithubContentSource? source,
    LocalStore? store,
    String? manifestUrlOverride,
  })  : _source = source ?? GithubContentSource(),
        _store = store ?? LocalStore.instance,
        _manifestUrlOverride = manifestUrlOverride;

  final GithubContentSource _source;
  final LocalStore _store;
  final String? _manifestUrlOverride;

  /// The effective manifest URL: a value saved from Settings wins, then the
  /// test/override value, then the compile-time default.
  String get manifestUrl {
    final stored = _store.getSetting<String>(PrefKeys.manifestUrl);
    if (stored != null && stored.trim().isNotEmpty) return stored.trim();
    final override = _manifestUrlOverride;
    if (override != null && override.trim().isNotEmpty) return override.trim();
    return AppConstants.githubManifestUrl;
  }

  bool get isConfigured => manifestUrl.trim().isNotEmpty;

  String get cachedVersion => _store.readContentCache()['version'] ?? '';

  Future<SyncResult> sync({bool force = false}) async {
    if (!isConfigured) {
      return const SyncResult(
        status: SyncStatus.notConfigured,
        message: 'GitHub কনটেন্ট সোর্স এখনো কনফিগার করা হয়নি। বান্ডেল করা কনটেন্ট ব্যবহার করা হচ্ছে।',
      );
    }

    try {
      final manifest = await _source.fetchManifest(manifestUrl);
      final localVersion = cachedVersion;

      if (!force &&
          localVersion.isNotEmpty &&
          _compareVersions(manifest.contentVersion, localVersion) <= 0) {
        await _store.setSetting(
          PrefKeys.lastSyncAt,
          DateTime.now().toIso8601String(),
        );
        return SyncResult(
          status: SyncStatus.upToDate,
          message: 'ইতিমধ্যে সর্বশেষ ভার্সন ($localVersion) আছে।',
          version: localVersion,
        );
      }

      final remote = await _source.fetchRaw(manifest, manifestUrl);
      await _store.writeContentCache(
        manifest: remote.manifest.contentVersion,
        stages: remote.stages,
        books: remote.books,
        memorization: remote.memorization,
        quizzes: remote.quizzes,
        schedule: remote.schedule,
        programs: remote.programs,
        version: remote.manifest.contentVersion,
      );
      await _store.setSetting(
        PrefKeys.contentVersion,
        remote.manifest.contentVersion,
      );
      await _store.setSetting(
        PrefKeys.lastSyncAt,
        DateTime.now().toIso8601String(),
      );

      return SyncResult(
        status: SyncStatus.updated,
        message: 'নতুন কনটেন্ট ডাউনলোড হয়েছে (${remote.manifest.contentVersion})।',
        version: remote.manifest.contentVersion,
      );
    } on ContentSyncException catch (e) {
      return SyncResult(
        status: SyncStatus.failed,
        message: 'সিংক ব্যর্থ: ${e.message}. পুরোনো কনটেন্ট অক্ষত রাখা হয়েছে।',
      );
    } catch (e) {
      return SyncResult(
        status: SyncStatus.failed,
        message: 'সিংক ব্যর্থ: $e. পুরোনো কনটেন্ট অক্ষত রাখা হয়েছে।',
      );
    }
  }

  static int _compareVersions(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }
}
