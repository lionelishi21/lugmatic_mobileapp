import 'package:flutter/material.dart';
import '../../../../core/theme/neumorphic_theme.dart';
import '../../../../data/services/playlist_service.dart';
import '../../../../core/network/api_client.dart';
import 'package:provider/provider.dart';

class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({Key? key}) : super(key: key);

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = true;
  bool _isLoading = false;
  late PlaylistService _playlistService;

  @override
  void initState() {
    super.initState();
    _playlistService = PlaylistService(apiClient: context.read<ApiClient>());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createPlaylist() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a playlist name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _playlistService.createPlaylist(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playlist "${_nameController.text}" created!'),
            backgroundColor: NeumorphicTheme.primaryAccent,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create playlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NeumorphicTheme.backgroundColor,
            NeumorphicTheme.surfaceColor,
            NeumorphicTheme.backgroundColor,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: NeumorphicButton(
            width: 50,
            height: 50,
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(15),
            onPressed: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: NeumorphicTheme.textPrimary),
          ),
          title: const Text(
            'Create Playlist',
            style: TextStyle(
              color: NeumorphicTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Playlist Cover
                Center(
                  child: NeumorphicContainer(
                    width: 180,
                    height: 180,
                    padding: const EdgeInsets.all(40),
                    borderRadius: BorderRadius.circular(30),
                    color: NeumorphicTheme.surfaceColor,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            NeumorphicTheme.primaryAccent,
                            NeumorphicTheme.secondaryAccent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Playlist Name
                Text(
                  'Playlist Name',
                  style: TextStyle(
                    color: NeumorphicTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                NeumorphicContainer(
                  isConcave: true,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(15),
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: NeumorphicTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: "My Awesome Playlist",
                      hintStyle: TextStyle(
                        color: NeumorphicTheme.textTertiary.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: NeumorphicTheme.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Description
                Text(
                  'Description (Optional)',
                  style: TextStyle(
                    color: NeumorphicTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                NeumorphicContainer(
                  isConcave: true,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(15),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: const TextStyle(color: NeumorphicTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Describe your playlist...",
                      hintStyle: TextStyle(
                        color: NeumorphicTheme.textTertiary.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: NeumorphicTheme.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Public/Private Toggle
                NeumorphicCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(15),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              NeumorphicTheme.primaryAccent,
                              NeumorphicTheme.secondaryAccent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isPublic ? Icons.public : Icons.lock,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isPublic ? 'Public Playlist' : 'Private Playlist',
                              style: const TextStyle(
                                color: NeumorphicTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isPublic
                                  ? 'Everyone can see this playlist'
                                  : 'Only you can see this playlist',
                              style: TextStyle(
                                color: NeumorphicTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPublic,
                        onChanged: (value) {
                          setState(() {
                            _isPublic = value;
                          });
                        },
                        activeColor: NeumorphicTheme.primaryAccent,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Create Button
                NeumorphicButton(
                  width: double.infinity,
                  height: 60,
                  isGradient: true,
                  gradientColors: [
                    NeumorphicTheme.primaryAccent,
                    NeumorphicTheme.secondaryAccent,
                  ],
                  onPressed: _isLoading ? null : _createPlaylist,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Playlist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

