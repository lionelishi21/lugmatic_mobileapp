import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/data/models/artist_model.dart';
import 'package:lugmatic_flutter/features/home/data/models/playlist_model.dart';
import 'package:lugmatic_flutter/ui/widgets/music_player_widget.dart';

class PlaylistDetailPage extends StatefulWidget {
  final PlaylistModel playlist;
  
  const PlaylistDetailPage({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  bool _isLiked = false;
  bool _isShuffled = false;

  final List<MusicModel> _songs = [
    MusicModel(
      id: '1',
      title: 'Midnight Dreams',
      artist: 'Luna Nova',
      album: 'Cosmic Vibes',
      imageUrl: 'https://via.placeholder.com/300x300/10B981/FFFFFF?text=Song1',
      audioUrl: 'https://example.com/song1.mp3',
      duration: const Duration(minutes: 3, seconds: 45),
      genre: 'Electronic',
      releaseDate: DateTime.now().subtract(const Duration(days: 30)),
    ),
    MusicModel(
      id: '2',
      title: 'Electric Storm',
      artist: 'Thunder Band',
      album: 'Lightning Strikes',
      imageUrl: 'https://via.placeholder.com/300x300/EF4444/FFFFFF?text=Song2',
      audioUrl: 'https://example.com/song2.mp3',
      duration: const Duration(minutes: 4, seconds: 12),
      genre: 'Rock',
      releaseDate: DateTime.now().subtract(const Duration(days: 25)),
    ),
    MusicModel(
      id: '3',
      title: 'Ocean Waves',
      artist: 'Chill Wave',
      album: 'Relaxation',
      imageUrl: 'https://via.placeholder.com/300x300/06B6D4/FFFFFF?text=Song3',
      audioUrl: 'https://example.com/song3.mp3',
      duration: const Duration(minutes: 5, seconds: 30),
      genre: 'Ambient',
      releaseDate: DateTime.now().subtract(const Duration(days: 20)),
    ),
    MusicModel(
      id: '4',
      title: 'City Lights',
      artist: 'Urban Beats',
      album: 'Metropolitan',
      imageUrl: 'https://via.placeholder.com/300x300/F59E0B/FFFFFF?text=Song4',
      audioUrl: 'https://example.com/song4.mp3',
      duration: const Duration(minutes: 3, seconds: 58),
      genre: 'Hip-Hop',
      releaseDate: DateTime.now().subtract(const Duration(days: 15)),
    ),
    MusicModel(
      id: '5',
      title: 'Sunset Boulevard',
      artist: 'Indie Dreams',
      album: 'New Horizons',
      imageUrl: 'https://via.placeholder.com/300x300/EC4899/FFFFFF?text=Song5',
      audioUrl: 'https://example.com/song5.mp3',
      duration: const Duration(minutes: 4, seconds: 25),
      genre: 'Indie',
      releaseDate: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  final List<ArtistModel> _contributors = [
    ArtistModel(
      id: '1',
      name: 'Luna Nova',
      imageUrl: 'https://via.placeholder.com/300x300/10B981/FFFFFF?text=Luna',
      bio: 'Electronic music producer and DJ',
      followers: 125000,
      isVerified: true,
      genres: ['Electronic', 'Ambient'],
      location: 'Los Angeles, CA',
    ),
    ArtistModel(
      id: '2',
      name: 'Thunder Band',
      imageUrl: 'https://via.placeholder.com/300x300/EF4444/FFFFFF?text=Thunder',
      bio: 'Rock band with electrifying performances',
      followers: 89000,
      isVerified: true,
      genres: ['Rock', 'Alternative'],
      location: 'Seattle, WA',
    ),
    ArtistModel(
      id: '3',
      name: 'Chill Wave',
      imageUrl: 'https://via.placeholder.com/300x300/06B6D4/FFFFFF?text=Chill',
      bio: 'Ambient and chill music creator',
      followers: 67000,
      isVerified: false,
      genres: ['Ambient', 'Chill'],
      location: 'Portland, OR',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildPlaylistHeader(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 32),
                _buildSortAndFilter(),
                const SizedBox(height: 16),
                _buildSongsList(),
                const SizedBox(height: 32),
                _buildContributors(),
                const SizedBox(height: 32),
                _buildPlaylistInfo(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF111827),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => _sharePlaylist(),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showPlaylistOptions(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF10B981).withOpacity(0.8),
                const Color(0xFF111827),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildPlaylistImage(),
                const SizedBox(height: 16),
                _buildPlaylistTitle(),
                const SizedBox(height: 8),
                _buildPlaylistSubtitle(),
                const SizedBox(height: 16),
                _buildPlaylistStats(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistImage() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          widget.playlist.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.music_note,
                size: 80,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaylistTitle() {
    return Text(
      widget.playlist.title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPlaylistSubtitle() {
    return Text(
      widget.playlist.subtitle,
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPlaylistStats() {
    final totalDuration = _songs.fold<Duration>(
      Duration.zero,
      (sum, song) => sum + song.duration,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${_songs.length} songs',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '${_formatDuration(totalDuration)}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(widget.playlist.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.playlist.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.playlist.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.playlist.type.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_songs.length} songs',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _playPlaylist(),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Play All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: IconButton(
              onPressed: () => setState(() => _isShuffled = !_isShuffled),
              icon: Icon(
                _isShuffled ? Icons.shuffle : Icons.shuffle_outlined,
                color: _isShuffled ? const Color(0xFF10B981) : Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: IconButton(
              onPressed: () => setState(() => _isLiked = !_isLiked),
              icon: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Songs',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.sort,
                  color: Colors.white.withOpacity(0.7),
                ),
                onSelected: (value) => print('Sort by: $value'),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Order Added',
                    child: Text('Order Added'),
                  ),
                  const PopupMenuItem(
                    value: 'Title',
                    child: Text('Title'),
                  ),
                  const PopupMenuItem(
                    value: 'Artist',
                    child: Text('Artist'),
                  ),
                  const PopupMenuItem(
                    value: 'Duration',
                    child: Text('Duration'),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: Colors.white.withOpacity(0.7),
                ),
                onPressed: () => _showFilterDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _songs.asMap().entries.map((entry) {
          final index = entry.key;
          final song = entry.value;
          return _buildSongItem(song, index + 1);
        }).toList(),
      ),
    );
  }

  Widget _buildSongItem(MusicModel song, int trackNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.02),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _playSong(song),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '$trackNumber',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(song.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(song.duration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white.withOpacity(0.5),
                    size: 20,
                  ),
                  onSelected: (value) => _handleSongAction(value, song),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'add_to_playlist',
                      child: Text('Add to Playlist'),
                    ),
                    const PopupMenuItem(
                      value: 'remove_from_playlist',
                      child: Text('Remove from Playlist'),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Text('Share'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContributors() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contributors',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _contributors.length,
              itemBuilder: (context, index) {
                final artist = _contributors[index];
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          image: DecorationImage(
                            image: NetworkImage(artist.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This Playlist',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A curated collection of ${widget.playlist.subtitle.toLowerCase()} music featuring ${_contributors.length} artists. This playlist was created to showcase the best tracks in the genre.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Created ${_formatDate(DateTime.now().subtract(const Duration(days: 30)))}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _playPlaylist() {
    if (_songs.isNotEmpty) {
      _playSong(_songs[0]);
    }
  }

  void _playSong(MusicModel song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerWidget(music: song),
        fullscreenDialog: true,
      ),
    );
  }

  void _handleSongAction(String action, MusicModel song) {
    switch (action) {
      case 'add_to_playlist':
        _showAddToPlaylistDialog(song);
        break;
      case 'remove_from_playlist':
        _removeSongFromPlaylist(song);
        break;
      case 'share':
        _shareSong(song);
        break;
    }
  }

  void _showAddToPlaylistDialog(MusicModel song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Add to Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Choose a playlist to add this song to.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added "${song.title}" to playlist'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeSongFromPlaylist(MusicModel song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Remove Song',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "${song.title}" from this playlist?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "${song.title}" from playlist'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _shareSong(MusicModel song) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared "${song.title}"'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _sharePlaylist() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared "${widget.playlist.title}" playlist'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _showPlaylistOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text('Edit Playlist', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                print('Edit playlist');
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white),
              title: const Text('Duplicate Playlist', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                print('Duplicate playlist');
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.white),
              title: const Text('Download Playlist', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                print('Download playlist');
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Playlist', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                print('Delete playlist');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Filter Songs',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Filter options will be available soon.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'today';
    if (difference == 1) return 'yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} weeks ago';
    if (difference < 365) return '${(difference / 30).floor()} months ago';
    return '${(difference / 365).floor()} years ago';
  }
}
