import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/artist_request_service.dart';
import '../../core/theme/neumorphic_theme.dart';

class DemandArtistDialog extends StatefulWidget {
  const DemandArtistDialog({Key? key}) : super(key: key);

  @override
  _DemandArtistDialogState createState() => _DemandArtistDialogState();
}

class _DemandArtistDialogState extends State<DemandArtistDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _genreController = TextEditingController();
  final _socialController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final service = context.read<ArtistRequestService>();
      await service.submitRequest(
        artistName: _nameController.text.trim(),
        genre: _genreController.text.trim().isEmpty ? null : _genreController.text.trim(),
        socialLink: _socialController.text.trim().isEmpty ? null : _socialController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artist request submitted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(30),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Demand Artist',
                      style: TextStyle(
                        color: NeumorphicTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: NeumorphicTheme.textTertiary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Help us grow our library by requesting your favorite artists.',
                  style: TextStyle(
                    color: NeumorphicTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: NeumorphicTheme.textPrimary),
                  decoration: NeumorphicTheme.neumorphicInputDecoration(
                    label: 'Artist Name',
                    hint: 'Who is missing?',
                    prefixIcon: Icons.person_add_alt_1,
                  ),
                  validator: (value) => 
                      value == null || value.trim().isEmpty ? 'Please enter artist name' : null,
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _genreController,
                  style: const TextStyle(color: NeumorphicTheme.textPrimary),
                  decoration: NeumorphicTheme.neumorphicInputDecoration(
                    label: 'Genre (Optional)',
                    hint: 'Amapiano, Afrobeats, etc.',
                    prefixIcon: Icons.music_note,
                  ),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _socialController,
                  style: const TextStyle(color: NeumorphicTheme.textPrimary),
                  decoration: NeumorphicTheme.neumorphicInputDecoration(
                    label: 'Social Link (Optional)',
                    hint: 'Instagram, Spotify, etc.',
                    prefixIcon: Icons.link,
                  ),
                ),
                const SizedBox(height: 32),
                
                NeumorphicButton(
                  onPressed: _isLoading ? null : _submit,
                  isGradient: true,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
