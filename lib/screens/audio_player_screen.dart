import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/media_file.dart';
import '../theme/app_theme.dart';

enum RepeatMode { none, one, all }

class AudioPlayerScreen extends StatefulWidget {
  final MediaFile file;
  final List<MediaFile> playlist;
  final int initialIndex;
  const AudioPlayerScreen({
    super.key, required this.file,
    required this.playlist, this.initialIndex = 0,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  late int _currentIndex;
  bool _isPlaying = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  RepeatMode _repeat = RepeatMode.none;
  bool _shuffle = false;
  double _volume = 1.0;
  late AnimationController _rotCtrl;
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _rotCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 12));
    _player = AudioPlayer();
    _setupListeners();
    _loadTrack();
  }

  void _setupListeners() {
    _subs.add(_player.positionStream.listen((p) {
      if (mounted) setState(() => _pos = p);
    }));
    _subs.add(_player.durationStream.listen((d) {
      if (mounted) setState(() => _dur = d ?? Duration.zero);
    }));
    _subs.add(_player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
      if (state.playing) _rotCtrl.repeat();
      else _rotCtrl.stop();
      if (state.processingState == ProcessingState.completed) _onComplete();
    }));
  }

  Future<void> _loadTrack() async {
    final file = widget.playlist[_currentIndex];
    try {
      await _player.setFilePath(file.path);
      await _player.play();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot play: $e'), backgroundColor: Colors.red));
    }
  }

  void _onComplete() {
    switch (_repeat) {
      case RepeatMode.one:
        _player.seek(Duration.zero); _player.play(); break;
      case RepeatMode.all:
        _nextTrack(wrap: true); break;
      case RepeatMode.none:
        if (_currentIndex < widget.playlist.length - 1) _nextTrack(); break;
    }
  }

  void _nextTrack({bool wrap = false}) {
    if (_shuffle) {
      _currentIndex = Random().nextInt(widget.playlist.length);
    } else if (_currentIndex < widget.playlist.length - 1) {
      _currentIndex++;
    } else if (wrap) {
      _currentIndex = 0;
    } else return;
    if (mounted) setState(() {});
    _loadTrack();
  }

  void _prevTrack() {
    if (_pos > const Duration(seconds: 3)) { _player.seek(Duration.zero); return; }
    if (_currentIndex > 0) { setState(() => _currentIndex--); _loadTrack(); }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2,'0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2,'0');
    return '$m:$s';
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _rotCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.playlist[_currentIndex];
    final maxMs = _dur.inMilliseconds.toDouble();
    final curMs = _pos.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(child: Column(children: [

        // ── Top bar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
              color: Colors.white,
              onPressed: () => Navigator.pop(context)),
            Expanded(child: Column(children: [
              const Text('NOW PLAYING', style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 2)),
              const SizedBox(height: 2),
              Text('${_currentIndex + 1} of ${widget.playlist.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ])),
            const SizedBox(width: 48),
          ]),
        ),

        const SizedBox(height: 24),

        // ── Rotating vinyl ──
        RotationTransition(
          turns: _rotCtrl,
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceBg,
              boxShadow: [
                BoxShadow(color: AppTheme.primaryOrange.withOpacity(0.25),
                  blurRadius: 60, spreadRadius: 10),
                const BoxShadow(color: Colors.black54, blurRadius: 30, spreadRadius: 5),
              ]),
            child: Stack(alignment: Alignment.center, children: [
              Container(width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10))),
              Container(width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A1A),
                  border: Border.all(color: Colors.white10))),
              Container(width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F0F0F),
                  border: Border.all(
                    color: AppTheme.primaryOrange.withOpacity(0.4), width: 2))),
              const Icon(Icons.music_note_rounded,
                color: AppTheme.primaryOrange, size: 22),
            ]),
          ),
        ),

        const SizedBox(height: 32),

        // ── Title & artist ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(children: [
            Text(file.displayName,
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            const SizedBox(height: 6),
            Text(file.artist ?? 'Unknown Artist',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ]),
        ),

        const SizedBox(height: 32),

        // ── Progress ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            Slider(
              min: 0, max: maxMs > 0 ? maxMs : 1.0, value: curMs,
              activeColor: AppTheme.primaryOrange,
              inactiveColor: Colors.white12,
              onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt()))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_fmt(_pos),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text(_fmt(_dur),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ])),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Controls ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            IconButton(
              icon: Icon(Icons.shuffle_rounded,
                color: _shuffle ? AppTheme.primaryOrange : Colors.white38),
              onPressed: () => setState(() => _shuffle = !_shuffle)),
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
              iconSize: 36, onPressed: _prevTrack),
            GestureDetector(
              onTap: () => _isPlaying ? _player.pause() : _player.play(),
              child: Container(
                width: 66, height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppTheme.primaryOrange,
                  boxShadow: [BoxShadow(
                    color: AppTheme.primaryOrange.withOpacity(0.45),
                    blurRadius: 24, spreadRadius: 4)]),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white, size: 38))),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
              iconSize: 36, onPressed: () => _nextTrack()),
            IconButton(
              icon: Icon(
                _repeat == RepeatMode.one
                  ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                color: _repeat != RepeatMode.none
                  ? AppTheme.primaryOrange : Colors.white38),
              onPressed: () => setState(() =>
                _repeat = RepeatMode.values[(_repeat.index + 1) % 3])),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Volume ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            const Icon(Icons.volume_down_rounded,
              color: AppTheme.textSecondary, size: 20),
            Expanded(child: Slider(
              min: 0, max: 1, value: _volume,
              activeColor: Colors.white60,
              inactiveColor: Colors.white12,
              onChanged: (v) {
                setState(() => _volume = v);
                _player.setVolume(v);
              })),
            const Icon(Icons.volume_up_rounded,
              color: AppTheme.textSecondary, size: 20),
          ]),
        ),
      ])),
    );
  }
}
