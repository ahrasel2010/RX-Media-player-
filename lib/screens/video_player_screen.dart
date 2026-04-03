import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;
import '../models/media_file.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MediaFile file;
  final List<MediaFile> playlist;
  final int initialIndex;
  const VideoPlayerScreen({
    super.key,
    required this.file,
    required this.playlist,
    this.initialIndex = 0,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _showControls = true;
  bool _isInitialized = false;
  bool _isLocked = false;
  Timer? _hideTimer;
  double _speed = 1.0;
  bool _isMuted = false;
  late int _currentIndex;
  late AnimationController _fadeCtrl;

  // Settings
  bool _autoPlayNext = true;
  bool _rememberPos = true;
  bool _subtitleEnabled = true;

  // Subtitle
  String? _subtitlePath;
  List<_SubEntry> _subs = [];
  String _currentSub = '';

  // Swipe to seek
  double? _swipeStartX;
  Duration? _swipeStartPos;
  bool _isSeeking = false;
  String _seekLabel = '';

  // Vertical gesture (volume)
  double? _swipeStartY;
  bool _isVolGesture = false;
  bool _showVolOverlay = false;
  double _volValue = 1.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 250));
    _fadeCtrl.value = 1.0;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _init();
  }

  Future<void> _init() async {
    _autoPlayNext    = await AppSettings.getAutoPlayNext();
    _rememberPos     = await AppSettings.getRememberPosition();
    _subtitleEnabled = await AppSettings.getShowSubtitles();
    _speed           = await AppSettings.getDefaultSpeed();
    await _load(widget.playlist[_currentIndex].path);
  }

  Future<void> _load(String path) async {
    // Save old position
    if (_controller != null && _rememberPos) {
      final pos = _controller!.value.position;
      final dur = _controller!.value.duration;
      if (pos.inSeconds > 3 && pos < dur - const Duration(seconds: 5)) {
        await AppSettings.savePosition(
          widget.playlist[_currentIndex].path, pos.inMilliseconds);
      }
    }

    await _controller?.dispose();
    _subs = [];
    _currentSub = '';
    if (mounted) setState(() => _isInitialized = false);

    // Build controller
    final ctrl = path.startsWith('http')
      ? VideoPlayerController.networkUrl(Uri.parse(path))
      : VideoPlayerController.file(File(path));
    _controller = ctrl;

    // Auto-detect subtitle
    _autoSub(path);

    try {
      await ctrl.initialize();
      ctrl.addListener(_onUpdate);
      await ctrl.setPlaybackSpeed(_speed);

      // Restore position
      if (_rememberPos) {
        final ms = await AppSettings.getSavedPosition(path);
        if (ms != null && ms > 3000) {
          final dur = ctrl.value.duration;
          final saved = Duration(milliseconds: ms);
          if (saved.inMilliseconds < dur.inMilliseconds - 10000) {
            await ctrl.seekTo(saved);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Resuming from ${_fmt(saved)}'),
                backgroundColor: AppTheme.surfaceBg,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ));
            }
          }
        }
      }

      await ctrl.play();
      if (mounted) setState(() => _isInitialized = true);
      _startHide();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot play: $e'), backgroundColor: Colors.red));
    }
  }

  void _autoSub(String videoPath) {
    final dir = p.dirname(videoPath);
    final name = p.basenameWithoutExtension(videoPath);
    for (final ext in ['srt','SRT','vtt','VTT','sub','SUB']) {
      final f = File(p.join(dir, '$name.$ext'));
      if (f.existsSync()) { _loadSub(f.path); break; }
    }
  }

  Future<void> _loadSub(String path) async {
    try {
      final raw = await File(path).readAsString();
      final entries = _parseSRT(raw);
      if (mounted) setState(() { _subtitlePath = path; _subs = entries; });
    } catch (_) {}
  }

  List<_SubEntry> _parseSRT(String content) {
    final list = <_SubEntry>[];
    for (final block in content.trim().split(RegExp(r'\n\s*\n'))) {
      final lines = block.trim().split('\n');
      if (lines.length < 3) continue;
      try {
        final parts = lines[1].split(' --> ');
        if (parts.length != 2) continue;
        final start = _srtTime(parts[0].trim());
        final end   = _srtTime(parts[1].trim());
        final text  = lines.sublist(2).join('\n').trim();
        list.add(_SubEntry(start: start, end: end, text: text));
      } catch (_) {}
    }
    return list;
  }

  Duration _srtTime(String s) {
    s = s.replaceAll(',', '.');
    final p1 = s.split(':');
    final h = int.parse(p1[0]);
    final m = int.parse(p1[1]);
    final sp = p1[2].split('.');
    final sec = int.parse(sp[0]);
    final ms = sp.length > 1 ? int.parse(sp[1].padRight(3,'0').substring(0,3)) : 0;
    return Duration(hours: h, minutes: m, seconds: sec, milliseconds: ms);
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {
      if (_subs.isNotEmpty && _subtitleEnabled) {
        final pos = _controller!.value.position;
        final match = _subs.where((e) => pos >= e.start && pos <= e.end);
        _currentSub = match.isNotEmpty ? match.first.text : '';
      }
    });
    final ctrl = _controller;
    if (ctrl == null) return;
    final dur = ctrl.value.duration;
    final pos = ctrl.value.position;
    if (dur > Duration.zero && pos >= dur - const Duration(milliseconds: 500)) {
      if (_autoPlayNext && _currentIndex < widget.playlist.length - 1) {
        _currentIndex++;
        _load(widget.playlist[_currentIndex].path);
      }
    }
  }

  void _startHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
        _fadeCtrl.reverse();
      }
    });
  }

  void _toggleControls() {
    if (_isLocked) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) { _fadeCtrl.forward(); _startHide(); }
    else _fadeCtrl.reverse();
  }

  void _playPause() {
    final ctrl = _controller; if (ctrl == null) return;
    if (ctrl.value.isPlaying) {
      ctrl.pause();
      _hideTimer?.cancel();
      setState(() => _showControls = true);
      _fadeCtrl.forward();
    } else { ctrl.play(); _startHide(); }
  }

  void _seek(Duration delta) {
    final ctrl = _controller; if (ctrl == null) return;
    Duration pos = ctrl.value.position + delta;
    if (pos < Duration.zero) pos = Duration.zero;
    if (pos > ctrl.value.duration) pos = ctrl.value.duration;
    ctrl.seekTo(pos);
  }

  void _next() {
    if (_currentIndex < widget.playlist.length - 1) {
      _currentIndex++; if (mounted) setState(() {}); _load(widget.playlist[_currentIndex].path);
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      _currentIndex--; if (mounted) setState(() {}); _load(widget.playlist[_currentIndex].path);
    }
  }

  String _fmt(Duration d) {
    final h = d.inHours, m = d.inMinutes.remainder(60), s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  // ── Subtitle picker ──
  void _subPicker() {
    final videoPath = widget.playlist[_currentIndex].path;
    List<FileSystemEntity> files = [];
    try {
      files = Directory(p.dirname(videoPath)).listSync().where((f) {
        final ext = p.extension(f.path).toLowerCase();
        return ['.srt','.vtt','.sub','.ass'].contains(ext);
      }).toList();
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const Padding(padding: EdgeInsets.all(12),
          child: Text('Subtitle নির্বাচন করুন',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),

        // Disable
        ListTile(
          leading: Icon(Icons.subtitles_off_rounded,
            color: _subtitlePath == null ? AppTheme.primaryOrange : Colors.white54),
          title: Text('Subtitle বন্ধ করুন',
            style: TextStyle(
              color: _subtitlePath == null ? AppTheme.primaryOrange : Colors.white)),
          onTap: () {
            Navigator.pop(context);
            setState(() { _subtitlePath = null; _subs = []; _currentSub = ''; });
          }),

        if (files.isEmpty)
          const Padding(padding: EdgeInsets.all(16),
            child: Text(
              'এই video এর পাশে .srt/.vtt file পাওয়া যায়নি।\nVideo এর একই folder এ subtitle file রাখুন।',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center))
        else
          ...files.map((f) => ListTile(
            leading: Icon(Icons.subtitles_rounded,
              color: _subtitlePath == f.path ? AppTheme.primaryOrange : Colors.white54),
            title: Text(p.basename(f.path),
              style: TextStyle(
                color: _subtitlePath == f.path ? AppTheme.primaryOrange : Colors.white)),
            onTap: () { Navigator.pop(context); _loadSub(f.path); })),
        const SizedBox(height: 12),
      ]),
    );
  }

  @override
  void dispose() {
    if (_controller != null && _rememberPos) {
      final pos = _controller!.value.position;
      final dur = _controller!.value.duration;
      if (pos.inSeconds > 3 && pos < dur - const Duration(seconds: 5)) {
        AppSettings.savePosition(widget.playlist[_currentIndex].path, pos.inMilliseconds);
      }
    }
    _hideTimer?.cancel();
    _fadeCtrl.dispose();
    _controller?.removeListener(_onUpdate);
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Tap → toggle controls
        onTap: _toggleControls,

        // Double tap → seek ±10s
        onDoubleTapDown: (d) {
          final left = d.localPosition.dx < size.width / 2;
          _seek(Duration(seconds: left ? -10 : 10));
        },

        // ── Horizontal swipe = seek ──
        onHorizontalDragStart: (d) {
          if (_isLocked) return;
          _swipeStartX = d.localPosition.dx;
          _swipeStartPos = _controller?.value.position;
          setState(() => _isSeeking = true);
        },
        onHorizontalDragUpdate: (d) {
          if (_isLocked || _swipeStartX == null || _swipeStartPos == null) return;
          final dx = d.localPosition.dx - _swipeStartX!;
          final secs = (dx * 0.4).round();
          Duration newPos = _swipeStartPos! + Duration(seconds: secs);
          if (newPos < Duration.zero) newPos = Duration.zero;
          final dur = _controller?.value.duration ?? Duration.zero;
          if (newPos > dur) newPos = dur;
          _controller?.seekTo(newPos);
          setState(() {
            _seekLabel = '${secs >= 0 ? "+" : ""}${secs}s  ${_fmt(newPos)}';
          });
        },
        onHorizontalDragEnd: (_) {
          setState(() => _isSeeking = false);
          _swipeStartX = null; _swipeStartPos = null;
        },

        // ── Vertical swipe = volume (right) ──
        onVerticalDragStart: (d) {
          if (_isLocked) return;
          _swipeStartY = d.localPosition.dy;
          _isVolGesture = d.localPosition.dx > size.width / 2;
          _volValue = _controller?.value.volume ?? 1.0;
          setState(() => _showVolOverlay = true);
        },
        onVerticalDragUpdate: (d) {
          if (_isLocked || _swipeStartY == null || !_isVolGesture) return;
          final dy = (_swipeStartY! - d.localPosition.dy) / size.height;
          _volValue = (_volValue + dy).clamp(0.0, 1.0);
          _controller?.setVolume(_volValue);
          setState(() {});
        },
        onVerticalDragEnd: (_) {
          setState(() => _showVolOverlay = false);
          _swipeStartY = null;
        },

        child: Stack(children: [
          // ── Video ──
          Center(
            child: _isInitialized
              ? AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!))
              : const CircularProgressIndicator(color: AppTheme.primaryOrange),
          ),

          // ── Subtitle text ──
          if (_isInitialized && _currentSub.isNotEmpty && _subtitleEnabled)
            Positioned(bottom: 60, left: 20, right: 20,
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(6)),
                child: Text(_currentSub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 16,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
              ))),

          // ── Seek swipe overlay ──
          if (_isSeeking)
            Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  _seekLabel.startsWith('+')
                    ? Icons.fast_forward_rounded
                    : Icons.fast_rewind_rounded,
                  color: AppTheme.primaryOrange, size: 24),
                const SizedBox(width: 8),
                Text(_seekLabel, style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
            )),

          // ── Volume overlay ──
          if (_showVolOverlay && _isVolGesture)
            Positioned(right: 24, top: 60,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _volValue > 0.5
                      ? Icons.volume_up_rounded
                      : (_volValue > 0 ? Icons.volume_down_rounded : Icons.volume_off_rounded),
                    color: Colors.white, size: 22),
                  const SizedBox(height: 6),
                  Text('${(_volValue * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                ]),
              )),

          // ── Lock icon ──
          if (_isLocked)
            Positioned(left: 16, top: 0, bottom: 0,
              child: Center(child: GestureDetector(
                onTap: () => setState(() => _isLocked = false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22)),
              ))),

          // ── Controls ──
          if (!_isLocked)
            FadeTransition(
              opacity: _fadeCtrl,
              child: _showControls ? _controls() : const SizedBox.shrink()),
        ]),
      ),
    );
  }

  Widget _controls() {
    final pos   = _controller?.value.position ?? Duration.zero;
    final dur   = _controller?.value.duration ?? Duration.zero;
    final play  = _controller?.value.isPlaying ?? false;
    final title = widget.playlist[_currentIndex].displayName;
    final maxMs = dur.inMilliseconds.toDouble();
    final curMs = pos.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 1.0);

    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.black87, Colors.transparent, Colors.transparent, Colors.black87],
        stops: [0, 0.3, 0.7, 1],
      )),
      child: Stack(children: [

        // ── Top bar ──
        Positioned(top: 0, left: 0, right: 0,
          child: SafeArea(child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: Colors.white,
              onPressed: () => Navigator.pop(context)),
            Expanded(child: Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis)),

            // Subtitle button
            IconButton(
              icon: Icon(Icons.subtitles_rounded,
                color: _subtitlePath != null
                  ? AppTheme.primaryOrange : Colors.white),
              onPressed: _subPicker,
              tooltip: 'Subtitle'),
            IconButton(
              icon: const Icon(Icons.lock_outline_rounded),
              color: Colors.white,
              onPressed: () => setState(() => _isLocked = true)),
            IconButton(
              icon: Icon(_isMuted
                ? Icons.volume_off_rounded : Icons.volume_up_rounded),
              color: Colors.white,
              onPressed: () {
                setState(() => _isMuted = !_isMuted);
                _controller?.setVolume(_isMuted ? 0 : 1);
              }),
            PopupMenuButton<double>(
              color: AppTheme.surfaceBg,
              icon: Text('${_speed}x',
                style: const TextStyle(color: Colors.white, fontSize: 13)),
              onSelected: (s) {
                setState(() => _speed = s);
                _controller?.setPlaybackSpeed(s);
              },
              itemBuilder: (_) => [0.25,0.5,0.75,1.0,1.25,1.5,2.0].map((s) =>
                PopupMenuItem(value: s, child: Row(children: [
                  if (_speed == s)
                    const Icon(Icons.check, color: AppTheme.primaryOrange, size: 16),
                  const SizedBox(width: 8),
                  Text('${s}x', style: const TextStyle(color: Colors.white)),
                ]))).toList()),
          ]))),

        // ── Center controls ──
        Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded),
            iconSize: 34,
            color: _currentIndex > 0 ? Colors.white : Colors.white30,
            onPressed: _currentIndex > 0 ? _prev : null),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _seek(const Duration(seconds: -10)),
            child: const Padding(padding: EdgeInsets.all(10),
              child: Icon(Icons.replay_10_rounded, color: Colors.white, size: 32))),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _playPause,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange, shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: AppTheme.primaryOrange.withOpacity(0.4),
                  blurRadius: 20, spreadRadius: 2)]),
              child: Icon(play ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: 36))),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _seek(const Duration(seconds: 10)),
            child: const Padding(padding: EdgeInsets.all(10),
              child: Icon(Icons.forward_10_rounded, color: Colors.white, size: 32))),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded),
            iconSize: 34,
            color: _currentIndex < widget.playlist.length - 1
              ? Colors.white : Colors.white30,
            onPressed: _currentIndex < widget.playlist.length - 1 ? _next : null),
        ])),

        // ── Bottom progress ──
        Positioned(bottom: 0, left: 0, right: 0,
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Slider(
                min: 0, max: maxMs > 0 ? maxMs : 1.0, value: curMs,
                activeColor: AppTheme.primaryOrange,
                inactiveColor: Colors.white24,
                onChanged: (v) => _controller?.seekTo(Duration(milliseconds: v.toInt()))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_fmt(pos),
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  if (_subtitlePath != null)
                    const Icon(Icons.subtitles_rounded,
                      color: AppTheme.primaryOrange, size: 14),
                  Text(_fmt(dur),
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ])),
            ]),
          ))),
      ]),
    );
  }
}

class _SubEntry {
  final Duration start, end;
  final String text;
  const _SubEntry({required this.start, required this.end, required this.text});
}
