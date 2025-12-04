import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
  });

  factory Song.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Song(
      id: doc.id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      album: data['album'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'artist': artist,
        'album': album,
      };
}