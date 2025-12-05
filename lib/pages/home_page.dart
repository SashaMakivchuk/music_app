import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/pages/favorites_page.dart';
import 'package:music_app/pages/library_page.dart';
import 'package:music_app/providers/auth_provider.dart';
import 'package:music_app/services/spotify_service.dart';
import 'package:music_app/widgets/song_tile.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  List<SpotifySong> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTopTracks();
  }

  Future<void> _loadTopTracks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await SpotifyService.getTopTracks();
      if (!mounted) return;
      setState(() => _searchResults = results);
    } catch (e) {
      if (!mounted) return;
      debugPrint("Error loading top tracks: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load songs: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _loadTopTracks();
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await SpotifyService.searchSongs(query);
      if (!mounted) return;
      setState(() => _searchResults = results);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music app'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music),
            tooltip: 'My Folders',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryPage())),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage())),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => ref.read(authProvider).signOut()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search songs, artists...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[800],
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _loadTopTracks();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _search, icon: const Icon(Icons.search)),
              ],
            ),
          ),
          
          if (_isLoading) const LinearProgressIndicator(color: Colors.green),

          Expanded(
            child: _isLoading && _searchResults.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.music_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No songs found.', style: TextStyle(color: Colors.grey)),
                            TextButton(onPressed: _loadTopTracks, child: const Text('Retry Loading')),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (_, i) => SongTile(song: _searchResults[i]),
                      ),
          ),
        ],
      ),
    );
  }
}