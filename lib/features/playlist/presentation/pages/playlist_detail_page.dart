import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/data/models/artist_model.dart';
import 'package:lugmatic_flutter/features/home/data/models/playlist_model.dart';
import 'package:lugmatic_flutter/data/providers/audio_provider.dart';
import 'package:lugmatic_flutter/ui/widgets/player_screen.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/comment_section_widget.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/services/playlist_service.dart';

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
  bool _isLoading = true;
  PlaylistModel? _playlist;
  late PlaylistService _playlistService;

  final List<MusicModel> _songs = [];

  final List<ArtistModel> _contributors = [];

  @override
  void initState() {
    super.initState();
    _playlistService = PlaylistService(apiClient: context.read<ApiClient>());
    _loadPlaylistDetails();
  }

  Future<void> _loadPlaylistDetails() async {
    try {
      final details = await _playlistService.getPlaylistDetails(widget.playlist.id);
      if (mounted) {
        setState(() {
          _playlist = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading playlist: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  void _duplicatePlaylist() async {
    if (_playlist == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copying playlist...'), duration: Duration(seconds: 1)),
      );

      final newPlaylist = await _playlistService.copyPlaylist(_playlist!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_playlist!.title}" copied to your library!'),
            backgroundColor: const Color(0xFF10B981),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/playlist_details',
                  arguments: newPlaylist,
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to copy playlist: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF111827),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    if (_playlist == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF111827),
        appBar: AppBar(
          backgroundColor: const Color(0xFF111827),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Playlist not found or an error occurred.',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

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
                const SizedBox(height: 48),
                CommentSectionWidget(
                  contentType: widget.playlist.type == 'album' ? 'album' : 'playlist',
                  contentId: widget.playlist.id,
                ),
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
    if (_playlist == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Hero(
            tag: 'playlist_art_${_playlist!.id}',
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
                image: DecorationImage(
                  image: NetworkImage(ApiConfig.resolveUrl(_playlist!.imageUrl)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _playlist!.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _playlist!.subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildPlaylistMetadata(),
        ],
      ),
    );
  }

  Widget _buildPlaylistMetadata() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_playlist!.ownerName != null) ...[
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
            child: Text(
              _playlist!.ownerName![0].toUpperCase(),
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _playlist!.ownerName!,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          _buildDot(),
        ],
        Text(
          '${_playlist!.songs.length} songs',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
        _buildDot(),
        Text(
          _playlist!.type.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _playPlaylist,
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Text(
                      'Play Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildCircleAction(
            _isShuffled ? Icons.shuffle : Icons.shuffle,
            _isShuffled ? const Color(0xFF10B981) : Colors.white.withOpacity(0.8),
            () => setState(() => _isShuffled = !_isShuffled),
          ),
          const SizedBox(width: 12),
          _buildCircleAction(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            _isLiked ? Colors.red : Colors.white.withOpacity(0.8),
            () => setState(() => _isLiked = !_isLiked),
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
    if (_playlist == null || _playlist!.songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'No songs in this playlist',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _playlist!.songs.asMap().entries.map((entry) {
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
                      image: NetworkImage(ApiConfig.resolveUrl(song.imageUrl)),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              song.artist,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (song.isArtistVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified,
                                color: Color(0xFF10B981),
                                size: 14,
                              ),
                            ),
                        ],
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
                      Stack(
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
                          if (artist.isVerified)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
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
    if (_playlist == null) return const SizedBox.shrink();
    
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
            _playlist!.description ?? 'A curated collection of ${_playlist!.subtitle.toLowerCase()} music.',
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
                Icons.calendar_today,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Updated recently',
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
    if (_playlist != null && _playlist!.songs.isNotEmpty) {
      context.read<AudioProvider>().playMusic(_playlist!.songs[0], queue: _playlist!.songs);
    }
  }

  void _playSong(MusicModel song) {
    if (_playlist == null) return;
    context.read<AudioProvider>().playMusic(song, queue: _playlist!.songs);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerScreen(music: song),
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
                _duplicatePlaylist();
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
