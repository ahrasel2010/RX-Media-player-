import 'package:flutter/material.dart';
import '../services/media_scanner_service.dart';
import '../theme/app_theme.dart';
import 'video_list_screen.dart';
import 'audio_list_screen.dart';
import 'settings_screen.dart';
import '../models/media_file.dart';
import 'video_player_screen.dart';
import 'audio_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final MediaScannerService _scanner = MediaScannerService();
  bool _isScanning = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scanMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _scanMedia() async {
    setState(() => _isScanning = true);
    await _scanner.scanDevice();
    if (mounted) setState(() => _isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange,
              borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('MX Player', style: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => showSearch(
              context: context,
              delegate: MediaSearchDelegate(
                videos: _scanner.videoFiles,
                audios: _scanner.audioFiles,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isScanning ? null : _scanMedia,
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () async {
              await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()));
              setState(() {});
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'VIDEOS'), Tab(text: 'AUDIO')],
        ),
      ),
      body: _isScanning
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryOrange),
                SizedBox(height: 20),
                Text('Scanning media files...',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                SizedBox(height: 8),
                Text('Storage থেকে সব video ও audio খোঁজা হচ্ছে...',
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ))
          : TabBarView(
              controller: _tabController,
              children: [
                VideoListScreen(videoFiles: _scanner.videoFiles, onRefresh: _scanMedia),
                AudioListScreen(audioFiles: _scanner.audioFiles, onRefresh: _scanMedia),
              ],
            ),
      floatingActionButton: _isScanning ? null : FloatingActionButton(
        onPressed: _scanMedia,
        backgroundColor: AppTheme.primaryOrange,
        tooltip: 'Scan again',
        child: const Icon(Icons.refresh_rounded, color: Colors.white),
      ),
    );
  }
}

// ── Search ──
class MediaSearchDelegate extends SearchDelegate<String> {
  final List<MediaFile> videos;
  final List<MediaFile> audios;
  MediaSearchDelegate({required this.videos, required this.audios});

  @override
  String get searchFieldLabel => 'Search videos, music...';

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF111111)),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: AppTheme.textSecondary),
      border: InputBorder.none,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Colors.white, fontSize: 16)),
  );

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  List<MediaFile> get _filtered {
    if (query.trim().isEmpty) return [...videos, ...audios];
    final q = query.toLowerCase();
    return [...videos, ...audios].where((f) =>
      f.name.toLowerCase().contains(q) ||
      (f.artist?.toLowerCase().contains(q) ?? false)).toList();
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = _filtered;
    if (results.isEmpty) {
      return Container(
        color: AppTheme.darkBg,
        child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, color: Colors.white24, size: 60),
            const SizedBox(height: 12),
            Text(query.isEmpty ? 'কিছু লিখুন...' : '"$query" পাওয়া যায়নি',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          ],
        )),
      );
    }
    return Container(
      color: AppTheme.darkBg,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (ctx, i) {
          final file = results[i];
          final isVideo = file.type == MediaType.video;
          return ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBg,
                borderRadius: BorderRadius.circular(8)),
              child: Icon(
                isVideo ? Icons.videocam_rounded : Icons.music_note_rounded,
                color: AppTheme.primaryOrange, size: 22),
            ),
            title: Text(file.displayName,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${file.extension.toUpperCase()} • ${file.formattedSize}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            trailing: Text(file.formattedDuration,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            onTap: () {
              close(context, '');
              if (isVideo) {
                final idx = videos.indexWhere((v) => v.path == file.path);
                Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    file: file,
                    playlist: videos.isEmpty ? [file] : videos,
                    initialIndex: idx < 0 ? 0 : idx)));
              } else {
                final idx = audios.indexWhere((a) => a.path == file.path);
                Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => AudioPlayerScreen(
                    file: file,
                    playlist: audios.isEmpty ? [file] : audios,
                    initialIndex: idx < 0 ? 0 : idx)));
              }
            },
          );
        },
      ),
    );
  }
}
