import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/app_colors.dart';

/// Inline audio player for one or many recitation sources.
///
/// Each entry in [sources] may be either an `http(s)://` URL or an absolute
/// local file path (from [AudioCacheService]), so playback works offline once
/// the audio has been downloaded.
///
/// Plays the sources as a continuous playlist. Reports the currently playing
/// index through [onIndexChanged] so the caller can highlight the matching
/// ayah, and exposes [AudioRecitationPlayerState.playAt] so a tap on a card
/// can jump straight to that ayah.
class AudioRecitationPlayer extends StatefulWidget {
  const AudioRecitationPlayer({
    super.key,
    required this.sources,
    this.onIndexChanged,
  });

  final List<String> sources;
  final ValueChanged<int>? onIndexChanged;

  @override
  State<AudioRecitationPlayer> createState() => AudioRecitationPlayerState();
}

class AudioRecitationPlayerState extends State<AudioRecitationPlayer> {
  final _player = AudioPlayer();
  StreamSubscription<int?>? _indexSub;
  String? _error;
  bool _loading = true;
  double _speed = 1.0;

  static const _speeds = [0.75, 1.0, 1.25, 1.5];

  /// Absolute playback position across the whole playlist.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Index of the track currently playing (null before the first track loads).
  int? get currentIndex => _player.currentIndex;

  /// Whether the playlist has finished.
  bool get isCompleted =>
      _player.processingState == ProcessingState.completed;

  static AudioSource _asSource(String s) {
    final uri = Uri.parse(s);
    if (uri.isScheme('http') || uri.isScheme('https')) {
      return AudioSource.uri(uri);
    }
    return AudioSource.file(s);
  }

  @override
  void initState() {
    super.initState();
    _sessionReady = _configureAudioSession();
    _indexSub = _player.currentIndexStream.listen((index) {
      if (index != null) widget.onIndexChanged?.call(index);
    });
    _load();
  }

  late final Future<void> _sessionReady;

  /// Declares this app as a music player so the platform audio sink is set up
  /// for media playback (some devices refuse to start a track otherwise).
  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (_) {
      // Non-fatal: playback may still work with the default configuration.
    }
  }

  @override
  void didUpdateWidget(covariant AudioRecitationPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Offline download finished (or new sources arrived): swap sources while
    // keeping the current track when possible.
    if (oldWidget.sources.join(' ') != widget.sources.join(' ')) {
      _load();
    }
  }

  Future<void> _load() async {
    await _sessionReady;
    final sources = widget.sources.map(_asSource).toList();
    if (sources.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'কোনো অডিও পাওয়া যায়নি।';
      });
      return;
    }
    final resumeIndex = _player.currentIndex ?? 0;
    final resumePos = _player.position;
    _error = null;
    try {
      await _player.setAudioSource(
        sources.length == 1
            ? sources.first
            : ConcatenatingAudioSource(children: sources),
      );
      await _player.setSpeed(_speed);
      if (resumeIndex > 0 && resumeIndex < sources.length) {
        await _player.seek(resumePos, index: resumeIndex);
      }
    } catch (_) {
      _error = 'অডিও লোড করা যায়নি। ইন্টারনেট সংযোগ পরীক্ষা করো।';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _indexSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  /// Jumps to [index] in the playlist and starts playing it.
  Future<void> playAt(int index) async {
    if (_error != null || widget.sources.isEmpty) return;
    try {
      await _player.seek(Duration.zero,
          index: index.clamp(0, widget.sources.length - 1));
      await _player.play();
    } catch (_) {
      // ignore seek errors (e.g. source failed to load)
    }
  }

  Future<void> _toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero, index: 0);
      }
      await _player.play();
    }
  }

  void _cycleSpeed() {
    final next = _speeds[(_speeds.indexOf(_speed) + 1) % _speeds.length];
    _player.setSpeed(next);
    setState(() => _speed = next);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.volume_off_rounded, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_error!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snap) {
              final ps = snap.data;
              return Text(
                'DBG st=${ps?.processingState.name} play=${ps?.playing} '
                'dur=${_player.duration?.inMilliseconds} '
                'pos=${_player.position.inMilliseconds} src=${widget.sources.length}',
                style: const TextStyle(color: Colors.yellow, fontSize: 9),
              );
            },
          ), _loading
          ? const SizedBox(
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final total = _player.duration ?? Duration.zero;
                final max = total.inMilliseconds.toDouble();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        StreamBuilder<PlayerState>(
                          stream: _player.playerStateStream,
                          builder: (context, snap) {
                            final playing = snap.data?.playing ?? false;
                            return IconButton(
                              onPressed: _toggle,
                              icon: Icon(
                                playing
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                size: 38,
                                color: AppColors.accent,
                              ),
                            );
                          },
                        ),
                        Expanded(
                          child: Slider(
                            value: max == 0
                                ? 0
                                : position.inMilliseconds
                                    .clamp(0, max)
                                    .toDouble(),
                            max: max == 0 ? 1 : max,
                            onChanged: max == 0
                                ? null
                                : (v) =>
                                    _player.seek(Duration(milliseconds: v.toInt())),
                          ),
                        ),
                        TextButton(
                          onPressed: _cycleSpeed,
                          child: Text('${_speed}x',
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 54, right: 54),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(position),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                          Text(_fmt(total),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
