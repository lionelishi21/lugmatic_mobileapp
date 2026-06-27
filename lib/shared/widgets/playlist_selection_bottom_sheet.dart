import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../data/models/music_model.dart';
import '../../data/models/playlist_model.dart';
import '../../data/services/playlist_service.dart';
import '../../features/home/presentation/pages/create_playlist_screen.dart';

class PlaylistSelectionBottomSheet extends StatefulWidget {
  final MusicModel song;

  const PlaylistSelectionBottomSheet({
    Key? key,
    required this.song,
  }) : super(key: key);

  @override
  State<PlaylistSelectionBottomSheet> createState() => _PlaylistSelectionBottomSheetState();
}

class _PlaylistSelectionBottomSheetState extends State<PlaylistSelectionBottomSheet> {
  bool _isLoading = true;
  String? _error;
  List<PlaylistModel> _playlists = [];
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  Future<void> _fetchPlaylists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiClient = context.read<ApiClient>();
      final playlistService = PlaylistService(apiClient: apiClient);
      final playlists = await playlistService.getUserPlaylists();
      
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load playlists: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToPlaylist(PlaylistModel playlist) async {
    if (_isAdding) return;
    
    setState(() => _isAdding = true);
    
    try {
      final apiClient = context.read<ApiClient>();
      final playlistService = PlaylistService(apiClient: apiClient);
      await playlistService.addSongToPlaylist(
        playlistId: playlist.id,
        songId: widget.song.id,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to ${playlist.title}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add: $e')),
        );
      }
    }
  }

  Future<void> _createAndAddPlaylist() async {
    final newPlaylist = await Navigator.push<PlaylistModel>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePlaylistScreen()),
    );
    if (newPlaylist != null && mounted) {
      await _addToPlaylist(newPlaylist);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: NeumorphicTheme.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NeumorphicTheme.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Add to Playlist',
            style: TextStyle(
              color: NeumorphicTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: NeumorphicTheme.primaryAccent));
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPlaylists,
              style: ElevatedButton.styleFrom(backgroundColor: NeumorphicTheme.primaryAccent),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You have no playlists yet.',
              style: TextStyle(color: NeumorphicTheme.textTertiary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createAndAddPlaylist,
              style: ElevatedButton.styleFrom(backgroundColor: NeumorphicTheme.primaryAccent),
              icon: const Icon(Icons.add),
              label: const Text('Create New Playlist'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          itemCount: _playlists.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: NeumorphicTheme.flatNeumorphicDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: NeumorphicTheme.primaryAccent),
                ),
                title: const Text(
                  'Create New Playlist',
                  style: TextStyle(
                    color: NeumorphicTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: _createAndAddPlaylist,
              );
            }
            final playlist = _playlists[index - 1];
            return ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: NeumorphicTheme.flatNeumorphicDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: playlist.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(playlist.imageUrl, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.music_note, color: NeumorphicTheme.primaryAccent),
              ),
              title: Text(
                playlist.title,
                style: const TextStyle(
                  color: NeumorphicTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${playlist.songs.length} songs',
                style: const TextStyle(color: NeumorphicTheme.textTertiary, fontSize: 12),
              ),
              onTap: () => _addToPlaylist(playlist),
            );
          },
        ),
        if (_isAdding)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: NeumorphicTheme.primaryAccent),
              ),
            ),
          ),
      ],
    );
  }
}
