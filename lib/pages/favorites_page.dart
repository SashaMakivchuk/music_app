import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/providers/song_provider.dart';
import 'package:music_app/widgets/song_tile.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteSongsAsync = ref.watch(favoriteSongsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: favoriteSongsAsync.when(
        data: (songs) => songs.isEmpty
            ? const Center(child: Text('No favorites yet – tap ♥ on any song!'))
            : ListView.builder(
                itemCount: songs.length,
                itemBuilder: (_, i) => SongTile(song: songs[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading favorites')),
      ),
    );
  }
}