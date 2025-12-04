import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/providers/song_provider.dart';

class SongTile extends ConsumerWidget {
  final Song song;
  const SongTile({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider.select((f) => f.contains(song.id)));

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Icon(Icons.music_note, color: Colors.white),
        ),
        title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${song.artist} • ${song.album}'),
        trailing: IconButton(
          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : null),
          onPressed: () => ref.read(favoritesProvider.notifier).toggle(song.id),
        ),
      ),
    );
  }
}