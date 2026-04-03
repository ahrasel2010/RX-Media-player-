import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/media_file.dart';
import '../theme/app_theme.dart';
import 'video_player_screen.dart';

class VideoListScreen extends StatefulWidget {
  final List<MediaFile> videoFiles;
  final Future<void> Function() onRefresh;
  const VideoListScreen({super.key, required this.videoFiles, required this.onRefresh});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  Map<String, List<MediaFile>> _folders = {};
  Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _buildFolders();
  }

  @override
  void didUpdateWidget(covariant VideoListScreen old) {
    super.didUpdateWidget(old);
    if (old.videoFiles.length != widget.videoFiles.length) _buildFolders();
  }

  void _buildFolders() {
    final map = <String, List<MediaFile>>{};
    for (final f in widget.videoFiles) {
      map.putIfAbsent(p.dirname(f.path), () => []).add(f);
    }
    setState(() {
      _folders = map;
      if (map.length == 1) _expanded = {map.keys.first};
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoFiles.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_rounded, size: 72, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No videos found',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Pull down to scan storage',
            style: TextStyle(color: Colors.white24, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text('Scan Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ));
    }

    return RefreshIndicator(
      color: AppTheme.primaryOrange,
      backgroundColor: AppTheme.cardBg,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _folders.entries.map((entry) {
          final folderPath = entry.key;
          final files = entry.value;
          final isExpanded = _expanded.contains(folderPath);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Folder header ──
              InkWell(
                onTap: () => setState(() {
                  if (isExpanded) _expanded.remove(folderPath);
                  else _expanded.add(folderPath);
                }),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(children: [
                    // Folder thumbnail = first video thumbnail
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      child: SizedBox(
                        width: 80, height: 58,
                        child: _ThumbWidget(path: files.first.path),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.basename(folderPath),
                          style: const TextStyle(color: Colors.white,
                            fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text('${files.length} video${files.length > 1 ? "s" : ""}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                      ],
                    )),
                    Icon(
                      isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                  ]),
                ),
              ),
              // ── Files inside folder ──
              if (isExpanded)
                ...files.map((file) {
                  final idx = widget.videoFiles.indexOf(file);
                  return _VideoTile(
                    file: file,
                    allFiles: widget.videoFiles,
                    index: idx < 0 ? 0 : idx,
                  );
                }),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Thumbnail widget ──
class _ThumbWidget extends StatefulWidget {
  final String path;
  const _ThumbWidget({required this.path});

  @override
  State<_ThumbWidget> createState() => _ThumbWidgetState();
}

class _ThumbWidgetState extends State<_ThumbWidget> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Try to find a cached thumbnail jpg beside the video
    final thumbPath = '${widget.path}.thumb.jpg';
    final f = File(thumbPath);
    if (await f.exists() && mounted) {
      setState(() => _file = f);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_file != null) {
      return Image.file(_file!, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF2A2A2A),
    child: const Icon(Icons.video_file_rounded, color: Colors.white24, size: 28),
  );
}

// ── Video tile ──
class _VideoTile extends StatelessWidget {
  final MediaFile file;
  final List<MediaFile> allFiles;
  final int index;
  const _VideoTile({required this.file, required this.allFiles, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          file: file, playlist: allFiles, initialIndex: index))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 2, 12, 2),
        decoration: BoxDecoration(
          color: AppTheme.cardBg, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            child: SizedBox(
              width: 110, height: 65,
              child: Stack(children: [
                Positioned.fill(child: _ThumbWidget(path: file.path)),
                Positioned(right: 4, bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(3)),
                    child: Text(file.formattedDuration,
                      style: const TextStyle(color: Colors.white, fontSize: 9)),
                  )),
              ]),
            ),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(file.displayName,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(children: [
                Text(file.extension.toUpperCase(),
                  style: const TextStyle(color: AppTheme.primaryOrange,
                    fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Text(file.formattedSize,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              ]),
            ]),
          )),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded,
              color: AppTheme.textSecondary, size: 18),
            onPressed: () => _options(context),
          ),
        ]),
      ),
    );
  }

  void _options(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        ListTile(
          leading: const Icon(Icons.play_arrow_rounded, color: AppTheme.primaryOrange),
          title: const Text('Play', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                file: file, playlist: allFiles, initialIndex: index)));
          }),
        ListTile(
          leading: const Icon(Icons.info_outline_rounded, color: Colors.white54),
          title: const Text('File Info', style: TextStyle(color: Colors.white)),
          onTap: () { Navigator.pop(context); _info(context); }),
        const SizedBox(height: 8),
      ]),
    );
  }

  void _info(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.surfaceBg,
      title: const Text('File Info', style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Name', file.displayName),
          _row('Type', file.extension.toUpperCase()),
          _row('Size', file.formattedSize),
          _row('Duration', file.formattedDuration),
          _row('Path', file.path),
        ]),
      actions: [TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close',
          style: TextStyle(color: AppTheme.primaryOrange)))],
    ));
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 13),
        maxLines: 2, overflow: TextOverflow.ellipsis),
    ]));
}
