import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/clash_pool_model.dart';
import '../../data/models/regular_clash_model.dart';
import '../../data/services/regular_clash_service.dart';
import 'regular_clash_detail_page.dart';

/// Standalone full-page version (with AppBar).
class RegularClashFeedPage extends StatelessWidget {
  const RegularClashFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text('⚡ Regular Clash', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: const RegularClashTabContent(),
    );
  }
}

/// Embeddable content — no Scaffold, suitable for use in a TabBarView.
class RegularClashTabContent extends StatefulWidget {
  const RegularClashTabContent({super.key});

  @override
  State<RegularClashTabContent> createState() => _RegularClashTabContentState();
}

class _RegularClashTabContentState extends State<RegularClashTabContent>
    with AutomaticKeepAliveClientMixin {
  late RegularClashService _service;

  ClashPoolModel? _activePool;
  List<RegularClashModel> _clashes = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedStatus; // null = all

  static const _tabs = ['All', 'Active', 'Voting', 'Ended'];
  static const _statusFilters = [null, 'active', 'voting', 'ended'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _service = RegularClashService(apiClient: context.read());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final pools = await _service.getActivePools();
      if (mounted) {
        _activePool = pools.isNotEmpty ? pools.first : null;
        await _loadFeed();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadFeed({String? status}) async {
    try {
      final clashes = await _service.getClashFeed(status: status ?? _selectedStatus);
      if (mounted) setState(() { _clashes = clashes; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        if (_activePool != null) _PoolBanner(pool: _activePool!),
        _FilterTabs(
          tabs: _tabs,
          selectedIndex: _statusFilters.indexOf(_selectedStatus),
          onTap: (i) {
            setState(() { _selectedStatus = _statusFilters[i]; _isLoading = true; });
            _loadFeed(status: _statusFilters[i]);
          },
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? _buildError()
                  : _buildClashList(),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: _loadData, child: const Text('Retry', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }

  Widget _buildClashList() {
    if (_clashes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_kabaddi, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 12),
            const Text('No clashes here yet', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _clashes.length,
        itemBuilder: (context, i) => MatchupCard(
          clash: _clashes[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegularClashDetailPage(
                clashId: _clashes[i].id,
                initialData: _clashes[i],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _FilterTabs({required this.tabs, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  color: selected ? AppColors.primary : Colors.white54,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PoolBanner extends StatelessWidget {
  final ClashPoolModel pool;
  const _PoolBanner({required this.pool});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final DateTime deadline;
    final String phaseLabel;
    if (pool.isOpen) {
      deadline = pool.challengeDeadline;
      phaseLabel = 'Challenge Period';
    } else if (pool.isSubmission) {
      deadline = pool.submissionDeadline;
      phaseLabel = 'Video Submission';
    } else if (pool.isVoting) {
      deadline = pool.votingDeadline;
      phaseLabel = 'Fan Voting';
    } else {
      deadline = pool.votingDeadline;
      phaseLabel = 'Ended';
    }

    final remaining = deadline.difference(now);
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.15), AppColors.secondary.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pool.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(
                  pool.isEnded ? 'Season ended' : '$phaseLabel • $days d $hours h left',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${pool.totalClashes} clashes',
              style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class MatchupCard extends StatelessWidget {
  final RegularClashModel clash;
  final VoidCallback onTap;

  const MatchupCard({super.key, required this.clash, required this.onTap});

  static const _realmColors = {
    'fire': Color(0xFFFF4500),
    'ice': Color(0xFF00BFFF),
    'reggae': Color(0xFF00C853),
    'dancehall': Color(0xFFFFD700),
    'hiphop': Color(0xFF9C27B0),
    'rnb': Color(0xFFE91E63),
    'afrobeats': Color(0xFFFF9800),
  };

  Color get _realmColor => _realmColors[clash.realm] ?? AppColors.primary;

  String get _statusLabel {
    switch (clash.status) {
      case 'pending': return 'Pending';
      case 'active': return 'Submitting';
      case 'voting': return 'VOTE';
      case 'ended': return 'Ended';
      case 'rejected': return 'Rejected';
      default: return clash.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVoting = clash.status == 'voting';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isVoting ? AppColors.primary.withOpacity(0.4) : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniArtist(clash.challenger),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isVoting ? AppColors.primary.withOpacity(0.2) : AppColors.muted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          color: isVoting ? AppColors.primary : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('VS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
                _miniArtist(clash.opponent),
              ],
            ),
            const SizedBox(height: 12),
            if (clash.totalVotes > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 4,
                  color: AppColors.secondary,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: clash.challengerVotePercent,
                    child: Container(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _realmColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    clash.realm.toUpperCase(),
                    style: TextStyle(color: _realmColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    if (clash.bothVideosSubmitted)
                      const Icon(Icons.play_circle_outline, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    const Icon(Icons.favorite_border, color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Text('${clash.likesCount}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniArtist(RegularClashArtist artist) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.muted,
          backgroundImage: artist.image != null ? NetworkImage(ApiConfig.resolveUrl(artist.image)) : null,
          child: artist.image == null ? const Icon(Icons.person, color: Colors.white54, size: 20) : null,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          child: Text(
            artist.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
