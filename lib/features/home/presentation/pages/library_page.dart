import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/music_model.dart';
import '../../../../data/models/artist_model.dart';
import '../../../../data/providers/audio_provider.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<PlaylistModel> _playlists = [];
  List<MusicModel> _songs = [];
  List<Map<String, dynamic>> _albums = [];
  List<ArtistModel> _artists = [];
  List<MusicModel> _history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final api = context.read<ApiClient>();
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        api.dio.get(ApiConfig.mobilePlaylists), // Fetches user playlists
        api.dio.get(ApiConfig.mobileFavorites, queryParameters: {'type': 'song'}), // Liked songs
        api.dio.get(ApiConfig.mobileFavorites, queryParameters: {'type': 'album'}), // Liked albums
        api.dio.get(ApiConfig.mobileFavorites, queryParameters: {'type': 'artist'}), // Following
        api.dio.get(ApiConfig.recentlyPlayed), // History
      ]);

      if (mounted) {
        final playlistBody = results[0].data;
        final favoritesBody = results[1].data;
        final albumBody = results[2].data;
        final artistBody = results[3].data;
        final historyBody = results[4].data;

        setState(() {
          final playlistsRaw = playlistBody['data'] ?? [];
          _playlists = (playlistsRaw as List).map((p) => PlaylistModel.fromJson(p as Map<String, dynamic>)).toList();
          
          // Fix: favorites and artists return { items: [...], nextCursor: ... }
          final songItems = favoritesBody['data']?['items'] ?? [];
          _songs = (songItems as List).map((j) => MusicModel.fromJson(j as Map<String, dynamic>)).toList();
          
          final albumItems = albumBody['data']?['items'] ?? [];
          _albums = List<Map<String, dynamic>>.from(albumItems);
          
          final artistItems = artistBody['data']?['items'] ?? [];
          _artists = (artistItems as List).map((j) => ArtistModel.fromJson(j as Map<String, dynamic>)).toList();
          
          // Fix: history returns { success, data: [ { song: {...}, playedAt: ... } ] }
          final historyRaw = historyBody['data'] ?? [];
          _history = (historyRaw as List)
              .map((item) => item['song'] != null 
                  ? MusicModel.fromJson(item['song'] as Map<String, dynamic>) 
                  : null)
              .whereType<MusicModel>()
              .toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildAppBar(),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF10B981),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.5),
                  labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Playlists'),
                    Tab(text: 'Liked Songs'),
                    Tab(text: 'Albums'),
                    Tab(text: 'Following'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPlaylistsTab(),
                  _buildSongsTab(), // Liked Songs
                  _buildAlbumsTab(),
                  _buildFollowingTab(),
                  _buildSongsTab(songs: _history), // History
                ],
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      title: const Text(
        'Library',
        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/mixer'),
          icon: const Icon(Icons.auto_awesome, color: Color(0xFF10B981)),
          tooltip: 'AI Mixer',
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.white)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.add, color: Colors.white)),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPlaylistsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPremiumBanner(),
        const SizedBox(height: 16),
        _buildCreatePlaylistCard(),
        const SizedBox(height: 24),
        if (_playlists.isEmpty)
          _buildEmptyState('No playlists yet', Icons.library_music)
        else
          ..._playlists.map((p) => _buildPlaylistItem(p)),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/premium'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lugmatic Premium', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Ad-free, High Quality & Offline', style: TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePlaylistCard() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(context, '/create_playlist');
        if (result == true) {
          _loadData(); // Refresh if created
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create New Playlist', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Start building your collection', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistItem(PlaylistModel playlist) {

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(context, '/playlist_details', arguments: playlist);
        },
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: playlist.imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ApiConfig.resolveUrl(playlist.imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.library_music, color: Colors.white, size: 24),
                  ),
                )
              : const Icon(Icons.library_music, color: Colors.white, size: 24),
        ),
        title: Text(playlist.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        subtitle: Text('${playlist.songs.length} songs', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.7)),
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildSongsTab({List<MusicModel>? songs}) {
    final list = songs ?? _songs;
    if (list.isEmpty) {
      return Center(child: _buildEmptyState('No songs in library', Icons.music_note));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final song = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.02),
          ),
          child: ListTile(
            onTap: () {
              final audioProvider = context.read<AudioProvider>();
              audioProvider.playMusic(song, queue: _songs);
            },
            leading: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF10B981).withOpacity(0.8), const Color(0xFF059669).withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: song.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(ApiConfig.resolveUrl(song.imageUrl), fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white, size: 24)),
                    )
                  : const Icon(Icons.music_note, color: Colors.white, size: 24),
            ),
            title: Text(song.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: Text(song.artist, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.6), size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowingTab() {
    if (_artists.isEmpty) {
      return Center(child: _buildEmptyState('No followed artists yet', Icons.people));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: ListTile(
            onTap: () {
              // Navigator.pushNamed(context, '/artist_details', arguments: artist);
            },
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: artist.imageUrl.isNotEmpty ? NetworkImage(
                ApiConfig.resolveUrl(artist.imageUrl)
              ) : null,
              child: artist.imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
            ),
            title: Text(artist.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            subtitle: Text('${artist.totalSongs} songs', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
            trailing: IconButton(
              icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.7)),
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    if (_artists.isEmpty) {
      return Center(child: _buildEmptyState('No artists found', Icons.person));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: ListTile(
            onTap: () {
              // Assuming '/artist' takes arguments or you might have '/artist_details'
              // The specific implementation depends on how Lugmatic app passes arguments
              // Here is a common pattern. Adjust to the actual route name used.
              // Navigator.pushNamed(context, '/artist_details', arguments: artist);
            },
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: artist.imageUrl.isNotEmpty ? NetworkImage(
                ApiConfig.resolveUrl(artist.imageUrl)
              ) : null,
              child: artist.imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
            ),
            title: Text(artist.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            subtitle: Text('${artist.totalSongs} songs', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
            trailing: IconButton(
              icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.7)),
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    if (_albums.isEmpty) {
      return Center(child: _buildEmptyState('No liked albums yet', Icons.album));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        final name = album['name']?.toString() ?? 'Unknown Album';
        final artist = album['artist']?.toString() ?? 'Unknown Artist';
        final coverArt = album['coverArt']?.toString() ?? '';

        return GestureDetector(
          onTap: () {
            // Navigator.pushNamed(context, '/album_details', arguments: album);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.05),
                    image: coverArt.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(ApiConfig.resolveUrl(coverArt)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: coverArt.isEmpty
                      ? const Center(child: Icon(Icons.album, color: Colors.white24, size: 48))
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                artist,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.3), size: 64),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar child;
  _StickyTabBarDelegate(this.child);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: const Color(0xFF111827), child: child);
  }

  @override
  double get maxExtent => child.preferredSize.height;
  @override
  double get minExtent => child.preferredSize.height;
  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}
