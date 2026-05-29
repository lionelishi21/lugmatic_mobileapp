import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/neumorphic_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/artist_service.dart';

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late ArtistService _artistService;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _artistService = context.read<ArtistService>();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.dio.get('/auth/me');
      final rawData = response.data['data'] ?? response.data;
      
      setState(() {
        _nameController.text = rawData['name'] ?? rawData['stageName'] ?? '';
        _bioController.text = rawData['bio'] ?? '';
        if (rawData['socialLinks'] != null) {
          _instagramController.text = rawData['socialLinks']['instagram'] ?? '';
          _twitterController.text = rawData['socialLinks']['twitter'] ?? '';
        }
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final artistId = auth.user?.artistId ?? auth.user?.id;
      if (artistId == null) throw Exception('Artist profile not linked');
      
      await _artistService.updateProfile(artistId, {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'socialLinks': {
          'instagram': _instagramController.text.trim(),
          'twitter': _twitterController.text.trim(),
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.screenGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Basic Info'),
                    const SizedBox(height: 16),
                    _buildInput('Stage Name', _nameController, Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildInput('Bio', _bioController, Icons.info_outline, maxLines: 5),
                    
                    const SizedBox(height: 32),
                    _buildSectionTitle('Social Links'),
                    const SizedBox(height: 16),
                    _buildInput('Instagram', _instagramController, Icons.camera_alt_outlined),
                    const SizedBox(height: 16),
                    _buildInput('Twitter', _twitterController, Icons.alternate_email),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Save Changes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.card,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.foreground),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.mutedForeground),
          prefixIcon: Icon(icon, color: AppColors.mutedForeground),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
