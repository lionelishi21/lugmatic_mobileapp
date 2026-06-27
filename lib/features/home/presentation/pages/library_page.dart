import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/music_model.dart';
import '../../../../data/models/artist_model.dart';
import '../../../../data/models/playlist_model.dart';
import '../../../../data/providers/audio_provider.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../data/services/music_service.dart';

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
  List<MusicModel> _artistSongs = [];

  // Each tab's fetch is independent — one section failing (auth hiccup, bad
  // response shape, etc.) must not blank out every other tab. Previously all
  // requests ran under one Future.wait with a single shared catch, so any one
  // failure silently emptied the entire page with no error shown anywhere.
  String? _playlistsError;
  String? _songsError;
  String? _albumsError;
  String? _artistsError;
  String? _historyError;
  String? _artistSongsError;
  bool _isArtist = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _isArtist = auth.user?.isArtist ?? false;
    _tabController = TabController(length: _isArtist ? 6 : 5, vsync: this);
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

    // Each section is fetched and error-handled independently so a failure in
    // any one (auth hiccup, malformed response, etc.) can't blank out the rest.
    await Future.wait([
      _loadPlaylists(api),
      _loadFavorites(api, type: 'song', onLoaded: (items) => _songs = items, onError: (e) => _songsError = e),
      _loadAlbums(api),
      _loadFollowing(api),
      _loadHistory(api),
      if (_isArtist) _loadArtistCatalog(api),
    ]);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadPlaylists(ApiClient api) async {
    try {
      final res = await api.dio.get(ApiConfig.mobilePlaylists);
      final raw = res.data['data'] ?? [];
      final playlists = (raw as List).map((p) => PlaylistModel.fromJson(p as Map<String, dynamic>)).toList();
      if (mounted) setState(() { _playlists = playlists; _playlistsError = null; });
    } catch (e) {
      if (mounted) setState(() => _playlistsError = e.toString());
    }
  }

  Future<void> _loadFavorites(
    ApiClient api, {
    required String type,
    required void Function(List<MusicModel>) onLoaded,
    required void Function(String?) onError,
  }) async {
    try {
      final res = await api.dio.get(ApiConfig.mobileFavorites, queryParameters: {'type': type});
      // Favorites return { items: [...], nextCursor: ... }
      final items = res.data['data']?['items'] ?? [];
      final songs = (items as List).map((j) => MusicModel.fromJson(j as Map<String, dynamic>)).toList();
      if (mounted) setState(() { onLoaded(songs); onError(null); });
    } catch (e) {
      if (mounted) setState(() => onError(e.toString()));
    }
  }

  Future<void> _loadAlbums(ApiClient api) async {
    try {
      final res = await api.dio.get(ApiConfig.mobileFavorites, queryParameters: {'type': 'album'});
      final items = res.data['data']?['items'] ?? [];
      final albums = List<Map<String, dynamic>>.from(items as List);
      if (mounted) setState(() { _albums = albums; _albumsError = null; });
    } catch (e) {
      if (mounted) setState(() => _albumsError = e.toString());
    }
  }

  Future<void> _loadFollowing(ApiClient api) async {
    try {
      final res = await api.dio.get(ApiConfig.mobileFavorites, queryParameters: {'type': 'artist'});
      final items = res.data['data']?['items'] ?? [];
      final artists = (items as List).map((j) => ArtistModel.fromJson(j as Map<String, dynamic>)).toList();
      if (mounted) setState(() { _artists = artists; _artistsError = null; });
    } catch (e) {
      if (mounted) setState(() => _artistsError = e.toString());
    }
  }

  Future<void> _loadHistory(ApiClient api) async {
    try {
      final res = await api.dio.get(ApiConfig.recentlyPlayed);
      // History returns { success, data: [ { song: {...}, playedAt: ... } ] }
      final raw = res.data['data'] ?? [];
      final history = (raw as List)
          .map((item) => item['song'] != null ? MusicModel.fromJson(item['song'] as Map<String, dynamic>) : null)
          .whereType<MusicModel>()
          .toList();
      if (mounted) setState(() { _history = history; _historyError = null; });
    } catch (e) {
      if (mounted) setState(() => _historyError = e.toString());
    }
  }

  Future<void> _loadArtistCatalog(ApiClient api) async {
    try {
      final songs = await MusicService(apiClient: api).getArtistCatalog();
      if (mounted) setState(() { _artistSongs = songs; _artistSongsError = null; });
    } catch (e) {
      if (mounted) setState(() => _artistSongsError = e.toString());
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
                  tabs: [
                    const Tab(text: 'Playlists'),
                    const Tab(text: 'Liked Songs'),
                    const Tab(text: 'Albums'),
                    const Tab(text: 'Following'),
                    const Tab(text: 'History'),
                    if (_isArtist) const Tab(text: 'Artist Music'),
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
                  _buildSongsTab(
                    error: _songsError,
                    onRetry: () => _loadFavorites(
                      context.read<ApiClient>(),
                      type: 'song',
                      onLoaded: (items) => _songs = items,
                      onError: (e) => _songsError = e,
                    ),
                  ), // Liked Songs
                  _buildAlbumsTab(),
                  _buildFollowingTab(),
                  _buildSongsTab(
                    songs: _history,
                    error: _historyError,
                    onRetry: () => _loadHistory(context.read<ApiClient>()),
                  ), // History
                  if (_isArtist) _buildArtistSongsTab(),
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
        if (_playlistsError != null)
          _buildErrorState(_playlistsError!, () => _loadPlaylists(context.read<ApiClient>()))
        else if (_playlists.isEmpty)
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
        if (result is PlaylistModel) {
          setState(() {
            _playlists.insert(0, result);
          });
        } else if (result == true) {
          _loadData(); // Fallback if returned true instead of model
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

  Widget _buildSongsTab({List<MusicModel>? songs, String? error, VoidCallback? onRetry}) {
    final list = songs ?? _songs;
    if (error != null) {
      return Center(child: _buildErrorState(error, onRetry ?? () {}));
    }
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
    if (_artistsError != null) {
      return Center(child: _buildErrorState(_artistsError!, () => _loadFollowing(context.read<ApiClient>())));
    }
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
              Navigator.pushNamed(context, '/artist', arguments: {'id': artist.id, 'initialData': artist});
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
              Navigator.pushNamed(context, '/artist', arguments: {'id': artist.id, 'initialData': artist});
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
    if (_albumsError != null) {
      return Center(child: _buildErrorState(_albumsError!, () => _loadAlbums(context.read<ApiClient>())));
    }
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

  // Distinct from _buildEmptyState — this means the fetch actually failed,
  // not that the user genuinely has nothing here. Always paired with Retry.
  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.redAccent.withOpacity(0.7), size: 48),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Could not load this — $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistSongsTab() {
    if (_artistSongsError != null) {
      return Center(child: _buildErrorState(_artistSongsError!, () => _loadArtistCatalog(context.read<ApiClient>())));
    }
    if (_artistSongs.isEmpty) {
      return Center(child: _buildEmptyState('No music in your artist catalog yet', Icons.library_music));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _artistSongs.length,
      itemBuilder: (context, index) {
        final song = _artistSongs[index];
        final isPrimary = song.role?.toLowerCase() == 'primary';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.04),
          ),
          child: ListTile(
            onTap: () {
              final audioProvider = context.read<AudioProvider>();
              audioProvider.playMusic(song, queue: _artistSongs);
            },
            leading: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: song.imageUrl.isNotEmpty ? DecorationImage(
                  image: NetworkImage(song.imageUrl),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: song.imageUrl.isEmpty ? const Icon(Icons.music_note, color: Colors.white24) : null,
            ),
            title: Row(
              children: [
                Expanded(child: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                if (song.role != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPrimary ? const Color(0xFF10B981) : Colors.blueAccent).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      song.role!.toUpperCase(),
                      style: TextStyle(
                        color: isPrimary ? const Color(0xFF10B981) : Colors.blueAccent,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '${song.artist}${song.share != null ? " • ${song.share!.round()}% share" : ""}',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
            trailing: const Icon(Icons.play_circle_outline, color: Color(0xFF10B981)),
          ),
        );
      },
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
