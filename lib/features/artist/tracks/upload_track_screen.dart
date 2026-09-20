import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/neumorphic_theme.dart';
import '../../../data/services/artist/upload_service.dart';
import '../../../data/providers/auth_provider.dart';
import 'lyrics_timing_screen.dart';

class UploadTrackScreen extends StatefulWidget {
  const UploadTrackScreen({super.key});

  @override
  State<UploadTrackScreen> createState() => _UploadTrackScreenState();
}

class _UploadTrackScreenState extends State<UploadTrackScreen> {
  late UploadService _uploadService;
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _selectedFile;
  File? _selectedCover;
  String _selectedType = 'song';
  String? _selectedGenreId;
  List<dynamic> _genres = [];
  
  bool _isLoadingGenres = true;
  bool _isUploading = false;
  double _uploadProgress = 0;

  PlatformFile? _selectedVideo;
  double _videoUploadProgress = 0;
  String? _createdSongId;
  bool _generatingLyrics = false;
  String _generatedLyrics = '';

  // AI-generated disclosure (all uploaders).
  bool _isAiGenerated = false;

  // Record-label artist attribution.
  bool _isLabel = false;
  bool _useExistingArtist = true;
  final _newArtistNameController = TextEditingController();
  final _artistSearchController = TextEditingController();
  Map<String, dynamic>? _selectedArtist;
  List<Map<String, dynamic>> _artistSearchResults = [];
  bool _searchingArtists = false;
  Timer? _artistSearchDebounce;

  @override
  void initState() {
    super.initState();
    _uploadService = context.read<UploadService>();
    _isLabel = context.read<AuthProvider>().hasLabelRole;
    _fetchGenres();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _newArtistNameController.dispose();
    _artistSearchController.dispose();
    _artistSearchDebounce?.cancel();
    super.dispose();
  }

  void _onArtistSearchChanged(String query) {
    _artistSearchDebounce?.cancel();
    _artistSearchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (query.trim().length < 2) {
        setState(() => _artistSearchResults = []);
        return;
      }
      setState(() => _searchingArtists = true);
      try {
        final results = await _uploadService.searchArtists(query);
        if (mounted) setState(() => _artistSearchResults = results);
      } catch (_) {
        if (mounted) setState(() => _artistSearchResults = []);
      } finally {
        if (mounted) setState(() => _searchingArtists = false);
      }
    });
  }

  Future<void> _fetchGenres() async {
    try {
      final genres = await _uploadService.getGenres();
      setState(() {
        _genres = genres;
        if (_genres.isNotEmpty) _selectedGenreId = _genres[0]['_id'];
        _isLoadingGenres = false;
      });
    } catch (e) {
      setState(() => _isLoadingGenres = false);
    }
  }

  // Matches the backend's actual limits (src/config/s3.js FILE_SIZE_LIMITS)
  // so oversized files are caught here instead of failing deep in the
  // network call with a generic error.
  static const _maxAudioBytes = 50 * 1024 * 1024;
  static const _maxImageBytes = 50 * 1024 * 1024;
  static const _maxVideoBytes = 200 * 1024 * 1024;

  void _showFileTooLarge(String label, int maxBytes) {
    final maxMb = maxBytes ~/ (1024 * 1024);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is too large. Max size is ${maxMb}MB.'), backgroundColor: Colors.red),
    );
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      if (file.size > _maxAudioBytes) {
        _showFileTooLarge('Audio file', _maxAudioBytes);
        return;
      }
      setState(() {
        _selectedFile = File(file.path!);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final size = await image.length();
      if (size > _maxImageBytes) {
        _showFileTooLarge('Cover image', _maxImageBytes);
        return;
      }
      setState(() {
        _selectedCover = File(image.path);
      });
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      final file = result.files.first;
      if (file.size > _maxVideoBytes) {
        _showFileTooLarge('Video', _maxVideoBytes);
        return;
      }
      setState(() => _selectedVideo = file);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null || _selectedCover == null || _selectedGenreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select files')),
      );
      return;
    }

    if (_isLabel) {
      final hasArtist = _useExistingArtist
          ? _selectedArtist != null
          : _newArtistNameController.text.trim().isNotEmpty;
      if (!hasArtist) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select or enter the artist this release is for')),
        );
        return;
      }
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      String? videoFileKey;

      // Upload video to S3 via presigned URL if selected
      if (_selectedVideo != null) {
        final videoBytes = _selectedVideo!.bytes ?? await File(_selectedVideo!.path!).readAsBytes();
        final videoPresign = await _uploadService.getPresignedUrl(
          type: 'music-video',
          filename: _selectedVideo!.name,
          contentType: 'video/mp4',
        );
        await _uploadService.uploadToS3(
          uploadUrl: videoPresign['uploadUrl'] as String,
          fileBytes: videoBytes,
          contentType: 'video/mp4',
          onProgress: (p) => setState(() => _videoUploadProgress = p),
        );
        videoFileKey = videoPresign['key'] as String?;
      }

      final result = await _uploadService.uploadContent(
        file: _selectedFile!,
        coverArt: _selectedCover!,
        title: _titleController.text.trim(),
        type: _selectedType,
        genreId: _selectedGenreId!,
        description: _descriptionController.text.trim(),
        videoFileKey: videoFileKey,
        isAiGenerated: _isAiGenerated,
        artistId: _isLabel && _useExistingArtist ? (_selectedArtist?['_id'] as String?) : null,
        unclaimedArtistName: _isLabel && !_useExistingArtist ? _newArtistNameController.text.trim() : null,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      final returnedSongId = result['_id'] as String? ?? result['id'] as String?;

      if (mounted) {
        setState(() {
          _isUploading = false;
          _createdSongId = returnedSongId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content uploaded successfully! It is now pending review.')),
        );
        if (_selectedType == 'song' && returnedSongId != null) {
          _showLyricsBanner();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  void _showLyricsBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: const Text(
          'Generate lyrics with AI based on your genre and title',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        leading: const Text('✨', style: TextStyle(fontSize: 20)),
        backgroundColor: AppColors.card,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              Navigator.pop(context);
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              await _generateAndShowLyrics();
            },
            child: _generatingLyrics
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text('Generate Lyrics'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndShowLyrics() async {
    if (_createdSongId == null) return;
    setState(() => _generatingLyrics = true);
    try {
      final lyrics = await _uploadService.generateLyrics(_createdSongId!);
      setState(() {
        _generatingLyrics = false;
        _generatedLyrics = lyrics;
      });
      if (mounted) _showLyricsBottomSheet(lyrics);
    } catch (e) {
      setState(() => _generatingLyrics = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate lyrics: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _showLyricsBottomSheet(String initialLyrics) {
    final lyricsController = TextEditingController(text: initialLyrics);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Generated Lyrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Edit the lyrics below before saving.',
                style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lyricsController,
                maxLines: 12,
                style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Lyrics will appear here...',
                  hintStyle: const TextStyle(color: AppColors.mutedForeground),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final edited = lyricsController.text;
                    try {
                      await _uploadService.updateSongLyrics(_createdSongId!, edited);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lyrics saved successfully!')),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save lyrics: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Save Lyrics', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final edited = lyricsController.text;
                    if (edited.trim().isEmpty || _selectedFile == null) return;
                    try {
                      await _uploadService.updateSongLyrics(_createdSongId!, edited);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Failed to save lyrics: $e')),
                        );
                      }
                      return;
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LyricsTimingScreen(
                            songId: _createdSongId!,
                            lyrics: edited,
                            audioFile: _selectedFile!,
                            uploadService: _uploadService,
                          ),
                        ),
                      );
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic, size: 18),
                      SizedBox(width: 8),
                      Text('Add Karaoke Timing', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      lyricsController.dispose();
      if (_createdSongId != null && mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Upload Content', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isUploading ? _buildUploadProgress() : _buildForm(),
    );
  }

  Widget _buildUploadProgress() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.cloudArrowUp, color: AppColors.primary, size: 64),
            const SizedBox(height: 32),
            Text(
              'Uploading your $_selectedType...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: AppColors.surfaceSubtle,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Text('${(_uploadProgress * 100).toInt()}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Selector
            Row(
              children: [
                _buildTypeChip('Song', 'song', FontAwesomeIcons.music),
                const SizedBox(width: 12),
                _buildTypeChip('Podcast', 'podcast', FontAwesomeIcons.microphone),
              ],
            ),
            const SizedBox(height: 32),

            // File Pickers
            _buildFilePicker(
              label: 'Audio File',
              hint: _selectedFile != null ? _selectedFile!.path.split('/').last : 'Select MP3/WAV file',
              icon: FontAwesomeIcons.fileAudio,
              onTap: _pickAudio,
            ),
            const SizedBox(height: 16),
            _buildFilePicker(
              label: 'Cover Art',
              hint: _selectedCover != null ? 'Image selected' : 'Select square image (1:1)',
              icon: FontAwesomeIcons.image,
              onTap: _pickImage,
              preview: _selectedCover,
            ),
            const SizedBox(height: 16),
            _buildFilePicker(
              label: 'Video (Optional)',
              hint: _selectedVideo != null ? _selectedVideo!.name : 'Select MP4 video',
              icon: FontAwesomeIcons.fileVideo,
              onTap: _pickVideo,
            ),
            const SizedBox(height: 32),

            // Text Fields
            _buildTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'Give it a name...',
              validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            
            // Genre Dropdown
            const Text('Genre', style: TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
            const SizedBox(height: 8),
            _isLoadingGenres 
              ? const CircularProgressIndicator()
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGenreId,
                      dropdownColor: AppColors.card,
                      isExpanded: true,
                      items: _genres.map((g) => DropdownMenuItem<String>(
                        value: g['_id'],
                        child: Text(g['name'], style: const TextStyle(color: AppColors.foreground)),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedGenreId = val),
                    ),
                  ),
                ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _descriptionController,
              label: 'Description (Optional)',
              hint: 'What\'s this about?',
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            if (_isLabel) ...[
              _buildArtistSelector(),
              const SizedBox(height: 16),
            ],

            _buildAiGeneratedToggle(),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('SUBMIT FOR REVIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String type, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: NeumorphicTheme.neumorphicDecoration(
            borderRadius: BorderRadius.circular(16),
          ).copyWith(
            color: isSelected ? AppColors.primary : AppColors.card,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 14, color: isSelected ? Colors.black : AppColors.mutedForeground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.mutedForeground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker({required String label, required String hint, required IconData icon, required VoidCallback onTap, File? preview}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                if (preview != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(preview, width: 40, height: 40, fit: BoxFit.cover),
                  )
                else
                  FaIcon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(color: AppColors.foreground.withValues(alpha: 0.7), fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Artist', style: TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildArtistModeChip('Existing Artist', true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildArtistModeChip('New Artist', false),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_useExistingArtist) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _artistSearchController,
              onChanged: (v) {
                setState(() => _selectedArtist = null);
                _onArtistSearchChanged(v);
              },
              style: const TextStyle(color: AppColors.foreground),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search for an artist by name...',
                hintStyle: const TextStyle(color: AppColors.mutedForeground),
                suffixIcon: _searchingArtists
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
            ),
          ),
          if (_selectedArtist != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                label: Text(_selectedArtist!['name'] as String? ?? ''),
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                onDeleted: () => setState(() {
                  _selectedArtist = null;
                  _artistSearchController.clear();
                  _artistSearchResults = [];
                }),
              ),
            )
          else if (_artistSearchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(12)),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _artistSearchResults.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.mutedForeground.withValues(alpha: 0.15)),
                itemBuilder: (_, i) {
                  final artist = _artistSearchResults[i];
                  return ListTile(
                    dense: true,
                    title: Text(artist['name'] as String? ?? '', style: const TextStyle(color: AppColors.foreground)),
                    onTap: () => setState(() {
                      _selectedArtist = artist;
                      _artistSearchResults = [];
                      _artistSearchController.text = artist['name'] as String? ?? '';
                    }),
                  );
                },
              ),
            ),
        ] else
          _buildTextField(
            controller: _newArtistNameController,
            label: 'Artist Name',
            hint: 'Name of the artist you\'re releasing this for',
          ),
      ],
    );
  }

  Widget _buildArtistModeChip(String label, bool value) {
    final isSelected = _useExistingArtist == value;
    return GestureDetector(
      onTap: () => setState(() {
        _useExistingArtist = value;
        _selectedArtist = null;
        _artistSearchResults = [];
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: NeumorphicTheme.neumorphicDecoration(
          borderRadius: BorderRadius.circular(16),
        ).copyWith(
          color: isSelected ? AppColors.primary : AppColors.card,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : AppColors.mutedForeground,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiGeneratedToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _isAiGenerated,
        activeThumbColor: AppColors.primary,
        onChanged: (v) => setState(() => _isAiGenerated = v),
        title: const Text('AI-generated', style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600)),
        subtitle: const Text(
          'This track was made using AI music generation tools',
          style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, int maxLines = 1, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: AppColors.foreground),
          decoration: NeumorphicTheme.neumorphicInputDecoration(label: 'Field', hint: hint),
        ),
      ],
    );
  }
}
