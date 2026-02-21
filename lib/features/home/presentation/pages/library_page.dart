import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/music_model.dart';
import '../../../../data/models/artist_model.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _playlists = [];
  List<MusicModel> _songs = [];
  List<Map<String, dynamic>> _albums = [];
  List<ArtistModel> _artists = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final api = context.read<ApiClient>();
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        api.dio.get(ApiConfig.playlists, queryParameters: {'limit': 20}),
        api.dio.get(ApiConfig.songs, queryParameters: {'limit': 30}),
        api.dio.get(ApiConfig.albums, queryParameters: {'limit': 20}),
        api.dio.get(ApiConfig.artists, queryParameters: {'limit': 20}),
      ]);

      if (mounted) {
        final playlistBody = results[0].data;
        final songBody = results[1].data;
        final albumBody = results[2].data;
        final artistBody = results[3].data;

        setState(() {
          _playlists = List<Map<String, dynamic>>.from(playlistBody['data'] ?? playlistBody['playlists'] ?? []);
          final songItems = songBody['data'] ?? songBody['songs'] ?? [];
          _songs = (songItems as List).map((j) => MusicModel.fromJson(j as Map<String, dynamic>)).toList();
          _albums = List<Map<String, dynamic>>.from(albumBody['data'] ?? albumBody['albums'] ?? []);
          final artistItems = artistBody['data'] ?? artistBody['artists'] ?? [];
          _artists = (artistItems as List).map((j) => ArtistModel.fromJson(j as Map<String, dynamic>)).toList();
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
                  tabs: const [
                    Tab(text: 'Playlists'),
                    Tab(text: 'Songs'),
                    Tab(text: 'Albums'),
                    Tab(text: 'Artists'),
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
                  _buildSongsTab(),
                  _buildAlbumsTab(),
                  _buildArtistsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: const Color(0xFF111827),
      elevation: 0,
      title: const Text(
        'Library',
        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      ),
      actions: [
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
        const SizedBox(height: 8),
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

  Widget _buildCreatePlaylistCard() {
    return Container(
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
    );
  }

  Widget _buildPlaylistItem(Map<String, dynamic> playlist) {
    final name = playlist['name']?.toString() ?? 'Untitled';
    final songCount = (playlist['songs'] is List) ? (playlist['songs'] as List).length : 0;

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
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.library_music, color: Colors.white, size: 24),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        subtitle: Text('$songCount songs', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
        trailing: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildSongsTab() {
    if (_songs.isEmpty) {
      return Center(child: _buildEmptyState('No songs in library', Icons.music_note));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.02),
          ),
          child: ListTile(
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
                      child: Image.network(song.imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white, size: 24)),
                    )
                  : const Icon(Icons.music_note, color: Colors.white, size: 24),
            ),
            title: Text(song.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: Text(song.artist, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border, color: Colors.white.withOpacity(0.6), size: 20),
                const SizedBox(width: 8),
                Icon(Icons.more_vert, color: Colors.white.withOpacity(0.6), size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    if (_albums.isEmpty) {
      return Center(child: _buildEmptyState('No albums yet', Icons.album));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.75,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        final name = album['name']?.toString() ?? 'Untitled';
        final coverArt = album['coverArt']?.toString() ?? '';
        final artistObj = album['artist'];
        final artistName = artistObj is Map ? (artistObj['name'] ?? '') : '';

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16), topRight: Radius.circular(16),
                    ),
                  ),
                  child: coverArt.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16), topRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            coverArt.startsWith('http') ? coverArt : 'https://api.lugmaticmusic.com$coverArt',
                            fit: BoxFit.cover, width: double.infinity,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.album, color: Colors.white, size: 48)),
                          ),
                        )
                      : const Center(child: Icon(Icons.album, color: Colors.white, size: 48)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(artistName, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
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
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: artist.imageUrl.isNotEmpty ? NetworkImage(
                artist.imageUrl.startsWith('http') ? artist.imageUrl : 'https://api.lugmaticmusic.com${artist.imageUrl}',
              ) : null,
              child: artist.imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
            ),
            title: Text(artist.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            subtitle: Text('${artist.totalSongs} songs', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
            trailing: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.7)),
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
