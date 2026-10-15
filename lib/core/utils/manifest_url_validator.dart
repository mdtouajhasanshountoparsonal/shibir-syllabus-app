/// Validates a GitHub-hosted `manifest.json` URL.
class ManifestUrlValidator {
  ManifestUrlValidator._();

  /// Returns an error message, or null when [value] is valid.
  static String? validate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'URL খালি রাখা যাবে না।';

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      return 'সঠিক URL দাও (https:// দিয়ে শুরু হবে)।';
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return 'শুধু http/https লিংক সমর্থিত।';
    }
    if (uri.host.isEmpty) return 'URL-এ হোস্ট নেই।';
    if (!uri.path.toLowerCase().endsWith('.json')) {
      return 'লিংকটি একটি JSON ফাইলের দিকে হতে হবে (যেমন manifest.json)।';
    }
    return null;
  }

  /// Whether the URL looks like a raw GitHub content URL.
  static bool looksLikeRawGithub(String value) =>
      value.trim().contains('raw.githubusercontent.com');
}
