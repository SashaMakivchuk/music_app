import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/providers/folder_provider.dart';
import 'package:music_app/widgets/song_tile.dart';

class FolderDetailPage extends ConsumerWidget {
  final String folderId;
  final String folderName;

  const FolderDetailPage({super.key, required this.folderId, required this.folderName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(folderTracksProvider(folderId));

    return Scaffold(
      appBar: AppBar(title: Text(folderName)),
      body: songsAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(
              child: Text('This folder is empty.\nAdd songs from the search page!', textAlign: TextAlign.center),
            );
          }
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (_, i) => SongTile(
              song: songs[i],
              currentFolderId: folderId, 
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}