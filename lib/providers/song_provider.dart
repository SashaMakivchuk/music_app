import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:music_app/providers/auth_provider.dart';
import 'package:music_app/services/spotify_service.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier(ref);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final Ref ref;
  String? uid;

  FavoritesNotifier(this.ref) : super({}) {
    final authState = ref.read(authStateProvider);
    uid = authState.value?.uid;
    if (uid != null) _loadFavorites();

    ref.listen(authStateProvider, (_, next) {
      final newUid = next.value?.uid;
      if (newUid != uid) {
        uid = newUid;
        if (uid != null) {
          _loadFavorites();
        } else {
          state = {};
        }
      }
    });
  }

  Future<void> _loadFavorites() async {
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .get();
      
      if (mounted) {
        state = snap.docs.map((doc) => doc.id).toSet();
      }
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    }
  }

  Future<void> toggle(String songId) async {
    if (uid == null) {
      debugPrint("User not logged in");
      return;
    }

    final isCurrentlyFavorite = state.contains(songId);
    if (isCurrentlyFavorite) {
      state = state.where((id) => id != songId).toSet();
    } else {
      state = {...state, songId};
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(songId);

    try {
      if (isCurrentlyFavorite) {
        await docRef.delete();
      } else {
        await docRef.set({'addedAt': FieldValue.serverTimestamp()});
      }
      ref.invalidate(favoriteSongsProvider);
    } catch (e) {
      debugPrint("DB Error, rolling back: $e");
      if (isCurrentlyFavorite) {
        state = {...state, songId};
      } else {
        state = state.where((id) => id != songId).toSet();
      }
      rethrow;
    }
  }
}

final favoriteSongsProvider = FutureProvider<List<SpotifySong>>((ref) async {
  final ids = ref.watch(favoritesProvider);
  if (ids.isEmpty) return [];
  
  try {
    return await SpotifyService.getTracksByIds(ids.toList());
  } catch (e) {
    debugPrint("Error fetching favorite details: $e");
    rethrow; 
  }
});