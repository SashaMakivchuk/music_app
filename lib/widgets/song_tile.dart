import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/pages/song_detail_page.dart';
import 'package:music_app/providers/song_provider.dart';
import 'package:music_app/providers/folder_provider.dart';
import 'package:music_app/services/spotify_service.dart';

class SongTile extends ConsumerWidget {
  final dynamic song;
  final String? currentFolderId;

  const SongTile({
    super.key, 
    required this.song,
    this.currentFolderId,
  });

  String get id => song.id;
  String get title => song is SpotifySong ? song.title : song.title;
  String get artist => song is SpotifySong ? song.artist : song.artist;
  String get album => song is SpotifySong ? song.album : song.album;
  String? get imageUrl => song is SpotifySong ? song.imageUrl : null;

  void _showAddToFolderSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final foldersAsync = ref.watch(foldersStreamProvider);
            
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add to Folder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Divider(),
                  Expanded(
                    child: foldersAsync.when(
                      data: (folders) {
                        if (folders.isEmpty) return const Center(child: Text('No folders created yet.'));
                        return ListView.builder(
                          itemCount: folders.length,
                          itemBuilder: (_, i) {
                            final folder = folders[i];
                            return ListTile(
                              leading: const Icon(Icons.folder_open, color: Colors.white70),
                              title: Text(folder.name),
                              subtitle: Text('${folder.songCount} songs'),
                              onTap: () {
                                ref.read(folderControllerProvider).addSongToFolder(folder.id, id);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Added to ${folder.name}')),
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(child: Text('Error loading folders')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider.select((favs) => favs.contains(id)));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[850],
      child: ListTile(
        leading: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[800]),
                  errorWidget: (_, __, ___) => const Icon(Icons.music_note),
                ),
              )
            : const CircleAvatar(child: Icon(Icons.music_note)),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentFolderId != null)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                onPressed: () {
                  ref.read(folderControllerProvider).removeSongFromFolder(currentFolderId!, id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Removed from folder')),
                  );
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.playlist_add),
                tooltip: 'Add to Folder',
                onPressed: () => _showAddToFolderSheet(context, ref),
              ),
            
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                 try {
                   ref.read(favoritesProvider.notifier).toggle(id);
                 } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
                 }
              },
            ),
          ],
        ),
        onTap: () {
          if (song is SpotifySong) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SongDetailPage(spotifySong: song)));
          }
        },
      ),
    );
  }
}