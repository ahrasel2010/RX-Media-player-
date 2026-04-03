import 'package:flutter/material.dart';
import '../models/media_file.dart';
import '../theme/app_theme.dart';
import 'audio_player_screen.dart';

class AudioListScreen extends StatelessWidget {
  final List<MediaFile> audioFiles;
  final Future<void> Function() onRefresh;
  const AudioListScreen({super.key, required this.audioFiles, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (audioFiles.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_music_rounded, size: 72, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No audio files found',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Pull down to scan storage',
            style: TextStyle(color: Colors.white24, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text('Scan Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ));
    }

    return RefreshIndicator(
      color: AppTheme.primaryOrange,
      backgroundColor: AppTheme.cardBg,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: audioFiles.length,
        itemBuilder: (ctx, i) {
          final file = audioFiles[i];
          return InkWell(
            onTap: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => AudioPlayerScreen(
                file: file, playlist: audioFiles, initialIndex: i))),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardBg, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBg, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.music_note_rounded,
                    color: AppTheme.primaryOrange, size: 26)),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(file.displayName, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(file.artist ?? 'Unknown Artist', maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                )),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(file.formattedDuration,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(file.extension.toUpperCase(),
                    style: const TextStyle(color: AppTheme.primaryOrange,
                      fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }
}
