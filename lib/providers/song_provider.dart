import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:music_app/providers/auth_provider.dart';
import 'package:music_app/models/song.dart';

final songsProvider = StreamProvider<List<Song>>((ref) {
  return FirebaseFirestore.instance
      .collection('songs')
      .snapshots()
      .map((s) => s.docs.map(Song.fromFirestore).toList());
});

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier(ref);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final Ref ref;
  String? uid;

  FavoritesNotifier(this.ref) : super({}) {
    ref.listen(authStateProvider, (_, next) {
      uid = next.value?.uid;
      if (uid != null) _load();
    });
  }

  Future<void> _load() async {
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .get();
    state = snap.docs.map((d) => d.id).toSet();
  }

  Future<void> toggle(String songId) async {
    if (uid == null) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(songId);

    if (state.contains(songId)) {
      await ref.delete();
      state = state.where((id) => id != songId).toSet();
    } else {
      await ref.set({});
      state = {...state, songId};
    }
  }

  bool isFavorite(String songId) => state.contains(songId);
}