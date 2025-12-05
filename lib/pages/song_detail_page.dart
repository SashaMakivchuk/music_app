import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/providers/song_provider.dart';
import 'package:music_app/services/spotify_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SongDetailPage extends ConsumerStatefulWidget {
  final SpotifySong spotifySong;
  const SongDetailPage({super.key, required this.spotifySong});

  @override
  ConsumerState<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends ConsumerState<SongDetailPage> {
  final player = AudioPlayer();
  bool isPlaying = false;
  Duration? duration;
  Duration? position;

  @override
  void initState() {
    super.initState();
    player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => isPlaying = state == PlayerState.playing);
      }
    });
    player.onDurationChanged.listen((d) => setState(() => duration = d));
    player.onPositionChanged.listen((p) => setState(() => position = p));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (widget.spotifySong.previewUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No preview available for this song')),
      );
      return;
    }

    if (isPlaying) {
      await player.pause();
    } else {
      await player.play(UrlSource(widget.spotifySong.previewUrl!));
    }
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '0:00';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.spotifySong;
    final minutes = (song.durationMs / 60000).floor();
    final seconds = ((song.durationMs % 60000) / 1000).floor();
    final isFavorite = ref.watch(favoritesProvider.select((favs) => favs.contains(song.id)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Song Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.withOpacity(0.8),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: song.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: song.imageUrl!,
                          width: 300,
                          height: 300,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, size: 100, color: Colors.white54),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, size: 100, color: Colors.white54),
                          ),
                        )
                      : Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.music_note, size: 120, color: Colors.white54),
                        ),
                ),

                const SizedBox(height: 40),

                Text(
                  song.title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  song.artist,
                  style: const TextStyle(fontSize: 20, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  song.album,
                  style: const TextStyle(fontSize: 16, color: Colors.white60),
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Duration', style: TextStyle(color: Colors.white60)),
                        Text(
                          '$minutes:${seconds.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Popularity', style: TextStyle(color: Colors.white60)),
                        Row(
                          children: [
                            Text(
                              '${song.popularity}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Text('%', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                if (song.previewUrl != null) ...[
                  Card(
                    color: Colors.white10,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                iconSize: 64,
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                    key: ValueKey(isPlaying),
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: _togglePlayPause,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position), style: const TextStyle(color: Colors.white70)),
                              Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                          Slider(
                            value: position?.inMilliseconds.toDouble() ?? 0,
                            max: duration?.inMilliseconds.toDouble() ?? 1,
                            onChanged: (value) async {
                              final pos = Duration(milliseconds: value.toInt());
                              await player.seek(pos);
                            },
                            activeColor: Colors.deepPurple,
                            inactiveColor: Colors.white24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('No preview available', style: TextStyle(color: Colors.white70)),
                  ),

                const SizedBox(height: 30),

                Consumer(
                  builder: (context, ref, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        label: Text(
                          isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFavorite ? Colors.red[700] : Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ref.read(favoritesProvider.notifier).toggle(song.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFavorite
                                  ? 'Removed from favorites'
                                  : 'Added to favorites!'),
                              backgroundColor: isFavorite ? Colors.red : Colors.green,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open in Spotify'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final url = Uri.parse('https://open.spotify.com/track/${song.id}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}                   