import 'package:just_audio/just_audio.dart';

/// Thin wrapper around [just_audio] used for letter/word/ayah playback.
///
/// Supports remote URLs (`https://…`) and bundled assets (`assets/…` or
/// `asset:assets/…`). Empty sources are ignored so callers can stay simple.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String source) async {
    if (source.isEmpty) return;
    try {
      await _player.stop();
      if (source.startsWith('asset:')) {
        await _player.setAsset(source.substring('asset:'.length));
      } else if (source.startsWith('assets/')) {
        await _player.setAsset(source);
      } else {
        await _player.setUrl(source);
      }
      await _player.play();
    } catch (_) {
      // Playback failures are non-fatal for an offline-first app.
    }
  }

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}
