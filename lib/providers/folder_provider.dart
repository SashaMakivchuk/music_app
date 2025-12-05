import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/providers/auth_provider.dart';
import 'package:music_app/services/spotify_service.dart';

class Folder {
  final String id;
  final String name;
  final int songCount;
  final DateTime createdAt;

  Folder({required this.id, required this.name, this.songCount = 0, required this.createdAt});

  factory Folder.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Folder(
      id: doc.id,
      name: data['name'] ?? 'Untitled',
      songCount: data['songCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

final foldersStreamProvider = StreamProvider<List<Folder>>((ref) {
  final userAsync = ref.watch(authStateProvider);
  final uid = userAsync.value?.uid;

  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('folders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Folder.fromDoc(doc)).toList());
});

final folderControllerProvider = Provider((ref) => FolderController(ref));

class FolderController {
  final Ref ref;
  FolderController(this.ref);

  String? get _uid => ref.read(authStateProvider).value?.uid;

  Future<void> createFolder(String name) async {
    if (_uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('folders')
        .add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'songCount': 0,
    });
  }

  Future<void> deleteFolder(String folderId) async {
    if (_uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('folders')
        .doc(folderId)
        .delete();
  }

  Future<void> addSongToFolder(String folderId, String songId) async {
    if (_uid == null) return;

    final folderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('folders')
        .doc(folderId);

    final trackRef = folderRef.collection('tracks').doc(songId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final trackDoc = await transaction.get(trackRef);
      if (trackDoc.exists) return;

      transaction.set(trackRef, {'addedAt': FieldValue.serverTimestamp()});
      transaction.update(folderRef, {'songCount': FieldValue.increment(1)});
    });
  }
  
  Future<void> removeSongFromFolder(String folderId, String songId) async {
    if (_uid == null) return;

    final folderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('folders')
        .doc(folderId);

    final trackRef = folderRef.collection('tracks').doc(songId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final trackDoc = await transaction.get(trackRef);
      if (!trackDoc.exists) return;

      transaction.delete(trackRef);
      transaction.update(folderRef, {'songCount': FieldValue.increment(-1)});
    });
    
    ref.invalidate(folderTracksProvider(folderId));
  }
}

final folderTracksProvider = FutureProvider.family<List<SpotifySong>, String>((ref, folderId) async {
  final uid = ref.read(authStateProvider).value?.uid;
  if (uid == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('folders')
      .doc(folderId)
      .collection('tracks')
      .orderBy('addedAt', descending: true)
      .get();

  if (snapshot.docs.isEmpty) return [];

  final ids = snapshot.docs.map((doc) => doc.id).toList();
  return SpotifyService.getTracksByIds(ids);
});