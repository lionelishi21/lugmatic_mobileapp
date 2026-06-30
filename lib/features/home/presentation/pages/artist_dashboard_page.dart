import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../data/services/management_service.dart';
import 'package:lugmatic_flutter/features/video/presentation/pages/video_recording_page.dart';
import '../../../../core/config/api_config.dart';

class ArtistDashboardPage extends StatefulWidget {
  const ArtistDashboardPage({Key? key}) : super(key: key);

  @override
  State<ArtistDashboardPage> createState() => _ArtistDashboardPageState();
}

class _ArtistDashboardPageState extends State<ArtistDashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _songs = [];
  String? _error;

  static const _kAccent = Color(0xFF8B5CF6);
  static const _kGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      final svc = context.read<ManagementService>();
      final artistId = auth.user?.artistId;
      if (artistId == null) throw Exception('Artist profile not found');

      final results = await Future.wait([
        svc.getArtistStats(artistId),
        svc.getArtistSongs(artistId),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _songs = results[1] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _fmt(dynamic n) {
    final v = (n is num ? n.toInt() : int.tryParse(n?.toString() ?? '0') ?? 0);
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final artistName = auth.user?.fullName ?? 'Artist';
    final profilePic = auth.user?.profilePicture;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kAccent))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: _kAccent,
                  child: CustomScrollView(
                    slivers: [
                      _buildHeroAppBar(artistName, profilePic),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatsRow(),
                              const SizedBox(height: 24),
                              _buildEarningsCard(),
                              const SizedBox(height: 24),
                              _buildQuickActions(),
                              const SizedBox(height: 28),
                              _buildSectionLabel('My Music', trailing: '${_songs.length} tracks'),
                              const SizedBox(height: 12),
                              _buildSongsList(),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeroAppBar(String name, String? profilePic) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A12),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A0A2E), Color(0xFF0F172A), Color(0xFF0A0A12)],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAccent.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: 10,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kGreen.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Artist info
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _kAccent.withValues(alpha: 0.2)),
                    // CircleAvatar's backgroundImage always centers its crop,
                    // cutting off the top of the head/face on a portrait photo.
                    // Image.network lets us bias the crop upward instead.
                    child: ClipOval(
                      child: profilePic != null && profilePic.isNotEmpty
                          ? Image.network(
                              ApiConfig.resolveUrl(profilePic),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white54, size: 36),
                            )
                          : const Icon(Icons.person, color: Colors.white54, size: 36),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_kAccent, Color(0xFF06B6D4)]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('ARTIST',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white54),
                    onPressed: _loadData,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final items = [
      _StatItem('Streams', _fmt(_stats['totalStreams']), Icons.play_circle_outline, const Color(0xFF10B981)),
      _StatItem('Listeners', _fmt(_stats['monthlyListeners']), Icons.headset_mic, const Color(0xFF8B5CF6)),
      _StatItem('Followers', _fmt(_stats['socialMediaFollowers']), Icons.people, const Color(0xFF06B6D4)),
    ];

    return Row(
      children: items.map((item) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.color.withValues(alpha: 0.12),
                item.color.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: item.color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: item.color, size: 20),
              const SizedBox(height: 8),
              Text(item.value,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(item.label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildEarningsCard() {
    final earnings = _stats['totalEarnings'] ?? 0;
    final monthlyEarnings = _stats['monthlyEarnings'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF065F46), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Earnings',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12)),
                const SizedBox(height: 6),
                Text('\$${earnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 4),
                    Text('\$${monthlyEarnings.toStringAsFixed(2)} this month',
                        style: const TextStyle(
                            color: Color(0xFF10B981), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: _kGreen, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _ActionItem('GO LIVE', Icons.live_tv_rounded, Colors.redAccent,
          () => Navigator.pushNamed(context, '/go_live')),
      _ActionItem('RECORD', Icons.videocam_rounded, _kAccent, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => VideoRecordingPage()));
      }),
      _ActionItem('CLASH', Icons.sports_kabaddi_rounded, const Color(0xFFFF8C00),
          () => Navigator.pushNamed(context, '/my_clashes')),
      _ActionItem('ANALYTICS', Icons.bar_chart_rounded, _kGreen, () {}),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Quick Actions'),
        const SizedBox(height: 12),
        Row(
          children: actions.map((a) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _QuickActionButton(item: a),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, {String? trailing}) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const Spacer(),
        if (trailing != null)
          Text(trailing,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
      ],
    );
  }

  Widget _buildSongsList() {
    if (_songs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            const Icon(Icons.music_off, color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            Text('No tracks uploaded yet',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 15)),
            const SizedBox(height: 8),
            Text('Upload your first track to get started',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25), fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _songs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final song = _songs[index];
        final isApproved =
            song['status'] == 'approved' || song['isApproved'] == true;
        final streams = song['playCount'] ?? song['streams'] ?? 0;
        final coverArt = song['coverArt'] ?? song['imageUrl'] ?? '';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: coverArt.isNotEmpty
                    ? Image.network(
                        ApiConfig.resolveUrl(coverArt),
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _artPlaceholder(),
                      )
                    : _artPlaceholder(),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song['name'] ?? 'Untitled',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(song['genre'] ?? '',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.play_arrow,
                            color: Colors.white24, size: 13),
                        const SizedBox(width: 3),
                        Text(_fmt(streams),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (isApproved ? _kGreen : Colors.orange)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isApproved ? _kGreen : Colors.orange)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  isApproved ? 'LIVE' : 'PENDING',
                  style: TextStyle(
                    color: isApproved ? _kGreen : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _artPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: Colors.white10,
      child: const Icon(Icons.music_note, color: Colors.white24, size: 24),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(backgroundColor: _kAccent),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ── Data classes ───────────────────────────────────────────────────────────────

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _ActionItem(this.label, this.icon, this.color, this.onTap);
}

class _QuickActionButton extends StatelessWidget {
  final _ActionItem item;
  const _QuickActionButton({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(item.icon, color: item.color, size: 22),
            const SizedBox(height: 6),
            Text(item.label,
                style: TextStyle(
                    color: item.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}
