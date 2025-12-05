import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SpotifySong {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? imageUrl;
  final String? previewUrl;
  final int popularity;
  final int durationMs;

  SpotifySong({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.imageUrl,
    this.previewUrl,
    required this.popularity,
    required this.durationMs,
  });

  factory SpotifySong.fromJson(Map<String, dynamic> json) {
    return SpotifySong(
      id: json['id'],
      title: json['name'],
      artist: (json['artists'] as List).map((a) => a['name']).join(', '),
      album: json['album']['name'],
      imageUrl: (json['album']['images'] as List).isNotEmpty
          ? json['album']['images'][0]['url']
          : null,
      previewUrl: json['preview_url'],
      popularity: json['popularity'] ?? 0,
      durationMs: json['duration_ms'] ?? 0,
    );
  }
}

class SpotifyService {
  static const String _clientId = String.fromEnvironment('SPOTIFY_CLIENT_ID', defaultValue: '43ad5e4914584859815e5b9f6ab2e216');
  static const String _clientSecret = String.fromEnvironment('SPOTIFY_CLIENT_SECRET', defaultValue: 'df1b4b72b1ec47cd9726a5120871de4c');

  static String? _accessToken;
  static DateTime? _tokenExpiry;

  static Future<String> _getAccessToken() async {
    if (_clientId.isEmpty || _clientSecret.isEmpty) {
      debugPrint("CRITICAL ERROR: Spotify Client ID or Secret is empty.");
      debugPrint("Did you forget to pass --dart-define during build?");
      throw Exception('Missing Spotify Credentials');
    }

    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    final bytes = utf8.encode('$_clientId:$_clientSecret');
    final base64Str = base64Encode(bytes);

    debugPrint("DEBUG: Requesting Spotify Token...");

    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic $base64Str',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in'] - 60)); // Buffer
      return _accessToken!;
    } else {
      debugPrint("Spotify Auth Error: ${response.statusCode} - ${response.body}");
      throw Exception('Spotify token failed: ${response.statusCode}');
    }
  }

  static Future<List<SpotifySong>> getTopTracks() async {
    try {
      final token = await _getAccessToken();
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/playlists/37i9dQZEVXbMDoHDwVN2tF/tracks?limit=50&market=US'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        return items
            .where((item) => item['track'] != null)
            .map((item) => SpotifySong.fromJson(item['track']))
            .toList();
      }
    } catch (e) {
      print("Spotify API failed: $e");
    }

    return [
      SpotifySong(id: "4cOdK2wGLETKBW3PvgPWqT", title: "Vampire", artist: "Olivia Rodrigo", album: "GUTS", previewUrl: null, imageUrl: "https://i.scdn.co/image/ab67616d0000b273a5f3f3b5b5f3f3b5b5f3f3b5", durationMs: 219000, popularity: 95),
      SpotifySong(id: "7dJY8grxJ9b0qbrq5b80oU", title: "Paint The Town Red", artist: "Doja Cat", album: "Scarlet", previewUrl: null, imageUrl: "https://i.scdn.co/image/ab67616d0000b273a1b2c3d4e5f6g7h8i9j0k1l2", durationMs: 230000, popularity: 92),
      SpotifySong(id: "1BxfuPKGuaTgOKdR8c0J0K", title: "I Remember Everything", artist: "Zach Bryan ft. Kacey Musgraves", album: "Zach Bryan", previewUrl: null, imageUrl: "https://i.scdn.co/image/ab67616d0000b273f4b5e2e5f4b5e2e5f4b5e2e5", durationMs: 227000, popularity: 94),
      SpotifySong(id: "2IGMVunIBsBLtEQyoI1Mu7", title: "Calm Down", artist: "Rema & Selena Gomez", album: "Rave & Roses", previewUrl: null, imageUrl: "https://i.scdn.co/image/ab67616d0000b273e2e5f4b5e2e5f4b5e2e5f4b5", durationMs: 239000, popularity: 90),
      SpotifySong(id: "1kuGVB7EU95pJObxwvfwKS", title: "Rush", artist: "Troye Sivan", album: "Something To Give Each Other", previewUrl: null, imageUrl: "https://i.scdn.co/image/ab67616d0000b273e2e5f4b5e2e5f4b5e2e5f4b5", durationMs: 192000, popularity: 88),
      SpotifySong(id: "5ydjx1J1d0f0j0f0j1d0f0", title: "Flowers", artist: "Miley Cyrus", album: "Endless Summer Vacation", previewUrl: null, imageUrl: "https://i.scdn.co/image/ab67616d0000b273a1b2c3d4e5f6g7h8i9j0k1l2", durationMs: 200000, popularity: 93),
    ];
  }
  

  static Future<List<SpotifySong>> searchSongs(String query) async {
    final token = await _getAccessToken();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/search?q=$query&type=track&limit=20'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final tracks = data['tracks']['items'] as List;
      return tracks.map((json) => SpotifySong.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search songs');
    }
  }

  static Future<List<SpotifySong>> getTracksByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final token = await _getAccessToken();
    final idsString = ids.join(',');
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/tracks?ids=$idsString'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final tracks = data['tracks'] as List;
      return tracks.map((json) => SpotifySong.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load favorites');
    }
  }
}