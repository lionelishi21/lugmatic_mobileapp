import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/management_service.dart';
import '../../../../core/constants/app_colors.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _overview = {};
  List<dynamic> _pendingArtists = [];
  List<dynamic> _pendingSongs = [];
  List<dynamic> _users = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mgmt = context.read<ManagementService>();
      
      final results = await Future.wait([
        mgmt.getAdminDashboardStats(),
        mgmt.getAdminArtists(page: 1),
        mgmt.getContentForModeration('songs'),
        mgmt.getAdminUsers(page: 1),
      ]);

      if (mounted) {
        setState(() {
          _overview = results[0] as Map<String, dynamic>;
          _pendingArtists = results[1] as List<dynamic>;
          _pendingSongs = results[2] as List<dynamic>;
          _users = results[3] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Admin Control Panel', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'ARTISTS'),
            Tab(text: 'MODERATION'),
            Tab(text: 'USERS'),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildArtistsTab(),
                _buildModerationTab(),
                _buildUsersTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _overview['overview'] ?? {};
    final revenue = _overview['revenue'] ?? {};
    
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Platform Statistics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatTile('Total Users', stats['totalUsers']?.toString() ?? '0', Icons.person_outline),
                _buildStatTile('Total Artists', stats['totalArtists']?.toString() ?? '0', Icons.mic_none),
                _buildStatTile('Total Revenue', '\$${revenue['total']?.toString() ?? '0'}', Icons.attach_money),
                _buildStatTile('Active Streams', stats['activeLiveStreams']?.toString() ?? '0', Icons.live_tv),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Recent Activity', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildRecentActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList() {
    final activities = _overview['recentActivity'] as List<dynamic>? ?? [];
    if (activities.isEmpty) return const Text('No recent activity', style: TextStyle(color: Colors.white24));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        final act = activities[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(_getActivityIcon(act['type']), color: AppColors.primary, size: 20),
          ),
          title: Text(act['artistName'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: Text(act['type']?.replaceAll('_', ' ').toUpperCase() ?? '', style: TextStyle(color: Colors.white30, fontSize: 10)),
          trailing: Text(
            _formatTimestamp(act['timestamp']),
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        );
      },
    );
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'track_upload': return Icons.cloud_upload;
      case 'live_stream': return Icons.live_tv;
      case 'artist_signup': return Icons.person_add;
      default: return Icons.notifications;
    }
  }

  String _formatTimestamp(String? ts) {
    if (ts == null) return '';
    final date = DateTime.parse(ts);
    return '${date.day}/${date.month}';
  }

  Widget _buildArtistsTab() {
    if (_pendingArtists.isEmpty) {
      return const Center(child: Text('No artists pending approval', style: TextStyle(color: Colors.white30)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingArtists.length,
      itemBuilder: (context, index) {
        final artist = _pendingArtists[index];
        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(artist['image'] ?? '')),
            title: Text(artist['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
            subtitle: Text(artist['genres']?.join(', ') ?? '', style: const TextStyle(color: Colors.white54)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _handleArtistReview(artist['_id'], true),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  onPressed: () => _handleArtistReview(artist['_id'], false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleArtistReview(String id, bool approved) async {
    final mgmt = context.read<ManagementService>();
    try {
      await mgmt.reviewArtist(id, approved, approved ? 'Approved via mobile dashboard' : 'Rejected via mobile dashboard');
      _loadAllData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approved ? 'Artist Approved' : 'Artist Rejected')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildModerationTab() {
     if (_pendingSongs.isEmpty) {
      return const Center(child: Text('No content pending moderation', style: TextStyle(color: Colors.white30)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingSongs.length,
      itemBuilder: (context, index) {
        final song = _pendingSongs[index];
        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.music_note, color: AppColors.primary),
            title: Text(song['name'] ?? 'Untitled', style: const TextStyle(color: Colors.white)),
            subtitle: const Text('New Track Upload', style: TextStyle(color: Colors.white54)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up, color: Colors.blueAccent),
                  onPressed: () => _handleModeration('songs', song['_id'], 'approve'),
                ),
                IconButton(
                  icon: const Icon(Icons.thumb_down, color: Colors.redAccent),
                  onPressed: () => _handleModeration('songs', song['_id'], 'reject'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleModeration(String type, String id, String action) async {
    final mgmt = context.read<ManagementService>();
    try {
      await mgmt.moderateContent(type, id, action, 'Moderated via mobile');
      _loadAllData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return ListTile(
          leading: CircleAvatar(child: Text(user['firstName']?[0] ?? 'U')),
          title: Text('${user['firstName']} ${user['lastName']}', style: const TextStyle(color: Colors.white)),
          subtitle: Text(user['email'] ?? '', style: const TextStyle(color: Colors.white54)),
          trailing: const Icon(Icons.more_vert, color: Colors.white24),
        );
      },
    );
  }
}
