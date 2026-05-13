import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:framer_motion/framer_motion.dart'; // Assuming Framer Motion or similar is available or use standard animations
import '../../../../core/theme/neumorphic_theme.dart';
import '../../../../data/models/live_clash_model.dart';
import '../../../../data/services/live_stream_service.dart';
import '../../../../core/config/api_config.dart';

class ClashesHubPage extends StatefulWidget {
  const ClashesHubPage({Key? key}) : super(key: key);

  @override
  State<ClashesHubPage> createState() => _ClashesHubPageState();
}

class _ClashesHubPageState extends State<ClashesHubPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late LiveStreamService _liveStreamService;

  bool _isLoading = true;
  List<LiveClashModel> _liveClashes = [];
  List<LiveClashModel> _pastClashes = [];
  List<Map<String, dynamic>> _rankings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _liveStreamService = LiveStreamService(apiClient: context.read());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _liveStreamService.getRecentClashes(limit: 10), // Assuming this can filter or we filter locally
        _liveStreamService.getClashRankings('all-time'),
      ]);

      if (mounted) {
        setState(() {
          final allClashes = results[0] as List<LiveClashModel>;
          _liveClashes = allClashes.where((c) => c.status == 'active').toList();
          _pastClashes = allClashes.where((c) => c.status == 'ended').toList();
          _rankings = results[1] as List<Map<String, dynamic>>;
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'LYRICAL WARS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.4),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'LIVE NOW'),
            Tab(text: 'PAST CLASHES'),
            Tab(text: 'RANKINGS'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildClashList(_liveClashes, 'No active clashes right now'),
                _buildClashList(_pastClashes, 'No past clashes yet'),
                _buildRankingsList(),
              ],
            ),
    );
  }

  Widget _buildClashList(List<LiveClashModel> clashes, String emptyMsg) {
    if (clashes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_kabaddi, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(emptyMsg, style: TextStyle(color: Colors.white.withOpacity(0.4))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clashes.length,
      itemBuilder: (context, index) => _ClashCard(clash: clashes[index]),
    );
  }

  Widget _buildRankingsList() {
    if (_rankings.isEmpty) {
      return const Center(child: Text('No rankings available', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rankings.length,
      itemBuilder: (context, index) {
        final rank = _rankings[index];
        final artist = rank['artist'] as Map<String, dynamic>?;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Text(
                '#${index + 1}',
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.black, fontSize: 18),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 24,
                backgroundImage: artist?['image'] != null ? NetworkImage(ApiConfig.resolveUrl(artist!['image'])) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(artist?['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${rank['wins']} Wins • ${rank['points']} Points', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
            ],
          ),
        );
      },
    );
  }
}

class _ClashCard extends StatelessWidget {
  final LiveClashModel clash;

  const _ClashCard({Key? key, required this.clash}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLive = clash.status == 'active';
    
    return GestureDetector(
      onTap: () {
        if (isLive) {
          Navigator.pushNamed(context, '/live', arguments: clash.streamId);
        } else {
          Navigator.pushNamed(context, '/clash', arguments: {'id': clash.id, 'initialData': clash});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLive ? const Color(0xFF10B981).withOpacity(0.3) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildArtistInfo(clash.challenger.name, clash.challenger.image, clash.challengerScore.toInt()),
                Column(
                  children: [
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                        child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      const Text('VS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.black, fontSize: 20)),
                  ],
                ),
                _buildArtistInfo(clash.opponent.name, clash.opponent.image, clash.opponentScore.toInt()),
              ],
            ),
            const SizedBox(height: 16),
            _buildScoreBar(),
            const SizedBox(height: 12),
            Text(
              clash.realm?.toUpperCase() ?? 'FIRE REALM',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistInfo(String name, String image, int score) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(ApiConfig.resolveUrl(image)),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(score.toString(), style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 18)),
      ],
    );
  }

  Widget _buildScoreBar() {
    final total = (clash.challengerScore + clash.opponentScore).clamp(1.0, double.infinity);
    final pct = clash.challengerScore / total;

    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(2)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: pct,
        child: Container(decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(2))),
      ),
    );
  }
}
