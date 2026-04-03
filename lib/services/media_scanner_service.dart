import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/media_file.dart';

class MediaScannerService {
  static const List<String> _videoExts = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'wmv',
    'flv',
    'webm',
    'm4v',
    '3gp',
    'ts',
    'mpeg',
    'mpg'
  ];

  static const List<String> _audioExts = [
    'mp3',
    'aac',
    'flac',
    'wav',
    'ogg',
    'm4a',
    'wma',
    'opus',
    'amr',
    '3ga'
  ];

  static final MediaScannerService _instance = MediaScannerService._internal();
  factory MediaScannerService() => _instance;
  MediaScannerService._internal();

  List<MediaFile> _videoFiles = [];
  List<MediaFile> _audioFiles = [];
  bool _isScanning = false;

  List<MediaFile> get videoFiles => List.unmodifiable(_videoFiles);
  List<MediaFile> get audioFiles => List.unmodifiable(_audioFiles);
  bool get isScanning => _isScanning;

  Future<void> scanDevice() async {
    if (_isScanning) return;
    _isScanning = true;

    _videoFiles.clear();
    _audioFiles.clear();

    try {
      final dirs = <String>[
        '/storage/emulated/0',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Videos',
        '/storage/emulated/0/WhatsApp/Media',
        '/storage/emulated/0/Telegram',
        '/storage/emulated/0/Bluetooth',
        '/storage/emulated/0/Recordings',
      ].where((d) => Directory(d).existsSync()).toList();

      for (final dir in dirs) {
        await _scan(dir);
      }
    } catch (e) {
      print('Scan error: $e');
    }

    _isScanning = false;
  }

  Future<void> _scan(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) return;

      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;

        final ext =
            p.extension(entity.path).replaceFirst('.', '').toLowerCase();

        if (!_videoExts.contains(ext) && !_audioExts.contains(ext)) continue;

        final stat = await entity.stat();
        if (stat.size < 50 * 1024) continue; // tiny file skip

        final isVideo = _videoExts.contains(ext);

        final file = MediaFile(
          path: entity.path,
          name: p.basename(entity.path),
          type: isVideo ? MediaType.video : MediaType.audio,
          size: stat.size,
        );

        if (isVideo) {
          if (!_videoFiles.any((f) => f.path == file.path)) {
            _videoFiles.add(file);
          }
        } else {
          if (!_audioFiles.any((f) => f.path == file.path)) {
            _audioFiles.add(file);
          }
        }
      }
    } catch (e) {
      print('Scan folder error: $e');
    }
  }
}
