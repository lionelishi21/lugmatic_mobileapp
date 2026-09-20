import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/neumorphic_theme.dart';
import '../../../data/models/artist/track_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/track_provider.dart';
import '../../../data/services/artist/track_service.dart';
import '../../../data/services/artist/upload_service.dart';

/// Only reachable for tracks with status == 'rejected' — the backend blocks
/// artists from editing approved/pending tracks. Saving here always
/// resubmits the track for review (see TrackService.updateTrack).
class EditTrackScreen extends StatefulWidget {
  final Track track;
  const EditTrackScreen({super.key, required this.track});

  @override
  State<EditTrackScreen> createState() => _EditTrackScreenState();
}

class _EditTrackScreenState extends State<EditTrackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  late TrackService _trackService;
  late UploadService _uploadService;

  TrackEditDetail? _detail;
  List<dynamic> _genres = [];
  String? _selectedGenreId;
  File? _newCoverArt;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _trackService = TrackService(apiClient: context.read<ApiClient>());
    _uploadService = context.read<UploadService>();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _trackService.getTrackDetails(widget.track.id),
        _uploadService.getGenres(),
      ]);
      final detail = results[0] as TrackEditDetail;
      final genres = results[1] as List<dynamic>;
      if (mounted) {
        setState(() {
          _detail = detail;
          _genres = genres;
          _titleController.text = detail.name;
          _selectedGenreId = detail.genreId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loadError = '$e'; _isLoading = false; });
    }
  }

  Future<void> _pickCoverArt() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _newCoverArt = File(image.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedGenreId == null) return;
    setState(() => _isSaving = true);
    try {
      await _trackService.updateTrack(
        trackId: widget.track.id,
        name: _titleController.text.trim(),
        genreId: _selectedGenreId!,
        coverArt: _newCoverArt,
      );
      if (mounted) {
        final auth = context.read<AuthProvider>();
        final artistId = auth.user?.artistId ?? auth.user?.id;
        if (artistId != null) context.read<TrackProvider>().fetchTracks(artistId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Track updated and resubmitted for review'), backgroundColor: AppColors.primary),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Edit Track', style: TextStyle(color: AppColors.foreground)),
        iconTheme: const IconThemeData(color: AppColors.foreground),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _loadError != null
              ? Center(child: Text(_loadError!, style: const TextStyle(color: AppColors.mutedForeground)))
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    final detail = _detail!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (detail.status != 'rejected')
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  "This track isn't in rejected status — saving may be blocked by the server.",
                  style: TextStyle(color: Colors.orange, fontSize: 13),
                ),
              ),
            if (detail.rejectionReason != null && detail.rejectionReason!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Why this was rejected', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(detail.rejectionReason!, style: const TextStyle(color: AppColors.foreground, fontSize: 14)),
                  ],
                ),
              ),

            Center(
              child: GestureDetector(
                onTap: _pickCoverArt,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.card,
                    image: _newCoverArt != null
                        ? DecorationImage(image: FileImage(_newCoverArt!), fit: BoxFit.cover)
                        : (detail.coverArtUrl != null && detail.coverArtUrl!.isNotEmpty)
                            ? DecorationImage(image: NetworkImage(detail.coverArtUrl!), fit: BoxFit.cover)
                            : null,
                  ),
                  child: (_newCoverArt == null && (detail.coverArtUrl == null || detail.coverArtUrl!.isEmpty))
                      ? const Icon(Icons.music_note, color: AppColors.mutedForeground, size: 40)
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.edit, color: Colors.black, size: 16),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Title', style: TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.foreground),
              decoration: NeumorphicTheme.neumorphicInputDecoration(label: 'Title', hint: 'Track title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),

            const Text('Genre', style: TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _genres.any((g) => g['_id'] == _selectedGenreId) ? _selectedGenreId : null,
                  hint: const Text('Select a genre', style: TextStyle(color: AppColors.mutedForeground)),
                  dropdownColor: AppColors.card,
                  isExpanded: true,
                  items: _genres.map<DropdownMenuItem<String>>((g) => DropdownMenuItem<String>(
                        value: g['_id'],
                        child: Text(g['name'], style: const TextStyle(color: AppColors.foreground)),
                      )).toList(),
                  onChanged: (val) => setState(() => _selectedGenreId = val),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Save & Resubmit for Review', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
