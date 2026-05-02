import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/artist_service.dart';
import '../../../../data/models/artist_model.dart';
import '../../../../data/models/music_model.dart';
import '../../../../ui/widgets/player_screen.dart';
import '../../../../data/providers/audio_provider.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../features/home/presentation/pages/artist_detail_page.dart';
import '../../features/live_stream/presentation/pages/go_live_setup_page.dart';
import '../../features/live_stream/presentation/pages/live_host_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authService = context.read<AuthService>();
    final user = await authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final user = _user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                    ? NetworkImage(user.profilePicture!)
                    : null,
                child: user.profilePicture == null || user.profilePicture!.isEmpty
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text('${user.fullName}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(user.email, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 8),
                Text('Coins: ${user.coins}', style: const TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            if (user.role == 'admin' || user.role == 'super admin') ...[
               SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/admin_dashboard'),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('ADMIN CONTROL PANEL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (user.isArtist && user.artistId != null) ...[
               SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/artist_dashboard'),
                  icon: const Icon(Icons.dashboard_customize),
                  label: const Text('ARTIST DASHBOARD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final artistService = context.read<ArtistService>();
                        final artist = await artistService.getArtistById(user.artistId!);
                        if (!mounted) return;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ArtistDetailPage(artistId: artist.id, initialData: artist)));
                      },
                      icon: const Icon(Icons.person, color: Colors.white, size: 18),
                      label: const Text('View Profile', style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GoLiveSetupPage()));
                      },
                      icon: const Icon(Icons.live_tv, color: Colors.white, size: 18),
                      label: const Text('GO LIVE', style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            const Divider(color: Colors.white24),
            _buildLegalLink(context, 'Privacy Policy', '/privacy'),
            _buildLegalLink(context, 'Terms of Service', '/terms'),
            const SizedBox(height: 32),
            Center(
              child: TextButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                child: const Text('LOGOUT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF0F172A),
    );
  }

  Widget _buildLegalLink(BuildContext context, String title, String route) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}



