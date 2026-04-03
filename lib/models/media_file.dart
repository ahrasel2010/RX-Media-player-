enum MediaType { video, audio }

class MediaFile {
  final String path;
  final String name;
  final MediaType type;
  final int? duration;
  final String? artist;
  final String? album;
  final int? size;

  const MediaFile({
    required this.path,
    required this.name,
    required this.type,
    this.duration,
    this.artist,
    this.album,
    this.size,
  });

  String get displayName => name.replaceAll(RegExp(r'\.[^.]+$'), '');
  String get extension => name.contains('.') ? name.split('.').last.toLowerCase() : '';

  String get formattedDuration {
    if (duration == null) return '--:--';
    final ms = duration!;
    final h = ms ~/ 3600000;
    final m = (ms % 3600000) ~/ 60000;
    final s = (ms % 60000) ~/ 1000;
    if (h > 0) {
      return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    }
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  String get formattedSize {
    if (size == null) return '';
    if (size! < 1024) return '${size}B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)}KB';
    if (size! < 1024 * 1024 * 1024) return '${(size! / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size! / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  static MediaType typeFromExtension(String ext) {
    const videoExts = ['mp4','mkv','avi','mov','wmv','flv','webm','m4v','3gp','ts','mpeg','mpg'];
    const audioExts = ['mp3','aac','flac','wav','ogg','m4a','wma','opus'];
    if (videoExts.contains(ext.toLowerCase())) return MediaType.video;
    if (audioExts.contains(ext.toLowerCase())) return MediaType.audio;
    return MediaType.video;
  }
}
