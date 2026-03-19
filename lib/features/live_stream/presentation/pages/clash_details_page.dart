import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neumorphic_theme.dart';
import '../../../../data/models/live_clash_model.dart';
import '../../../../data/services/live_stream_service.dart';
import '../../../../shared/widgets/comment_section_widget.dart';
import '../widgets/battle_bar_widget.dart';

class ClashDetailsPage extends StatefulWidget {
  final String clashId;
  final LiveClashModel? initialData;

  const ClashDetailsPage({
    Key? key,
    required this.clashId,
    this.initialData,
  }) : super(key: key);

  @override
  State<ClashDetailsPage> createState() => _ClashDetailsPageState();
}

class _ClashDetailsPageState extends State<ClashDetailsPage> {
  late LiveClashModel _clash;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _clash = widget.initialData!;
    } else {
      _fetchClashDetails();
    }
  }

  Future<void> _fetchClashDetails() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<LiveStreamService>();
      final data = await service.getClashDetails(widget.clashId);
      if (mounted) {
        setState(() {
          _clash = data;
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: NeumorphicTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: NeumorphicTheme.backgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final isWinnerChallenger = (_clash.winnerId == _clash.challenger.id);
    final isWinnerOpponent = (_clash.winnerId == _clash.opponent.id);
    final isDraw = _clash.winnerId == null && _clash.status == 'ended';

    return Scaffold(
      backgroundColor: NeumorphicTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: NeumorphicTheme.backgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'CLASH REVIEW',
                style: TextStyle(
                  color: NeumorphicTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
              background: _buildHeaderBackground(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Battle Bar (Stationary)
                  BattleBarWidget(
                    challengerScore: _clash.challengerScore,
                    opponentScore: _clash.opponentScore,
                    challengerName: _clash.challenger.name,
                    opponentName: _clash.opponent.name,
                    durationSeconds: _clash.duration,
                    startTime: null, // Don't start timer
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Winner Announcement
                  _buildWinnerAnnouncement(isWinnerChallenger, isWinnerOpponent, isDraw),
                  
                  const SizedBox(height: 40),
                  
                  // Stats Section
                  _buildStatsSection(),
                  
                  const SizedBox(height: 40),
                  
                  // Comments Section
                  CommentSectionWidget(
                    contentType: 'clash',
                    contentId: _clash.id,
                  ),
                  
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            NeumorphicTheme.primaryAccent.withOpacity(0.2),
            NeumorphicTheme.backgroundColor,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.emoji_events,
          size: 100,
          color: NeumorphicTheme.primaryAccent.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildWinnerAnnouncement(bool isChallenger, bool isOpponent, bool isDraw) {
    String text = 'DRAW';
    String winnerName = '';
    Color color = NeumorphicTheme.textSecondary;

    if (isChallenger) {
      text = 'WINNER';
      winnerName = _clash.challenger.name;
      color = Colors.amber;
    } else if (isOpponent) {
      text = 'WINNER';
      winnerName = _clash.opponent.name;
      color = Colors.amber;
    }

    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        if (!isDraw) ...[
          const SizedBox(height: 8),
          Text(
            winnerName.toUpperCase(),
            style: const TextStyle(
              color: NeumorphicTheme.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildArtistStat(_clash.challenger.name, _clash.challenger.image, _clash.challengerScore),
          const Text('VS', style: TextStyle(color: NeumorphicTheme.textTertiary, fontWeight: FontWeight.bold)),
          _buildArtistStat(_clash.opponent.name, _clash.opponent.image, _clash.opponentScore),
        ],
      ),
    );
  }

  Widget _buildArtistStat(String name, String image, double score) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: NeumorphicTheme.primaryAccent.withOpacity(0.3), width: 3),
            image: DecorationImage(
              image: NetworkImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: NeumorphicTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score.toInt().toString(),
          style: const TextStyle(
            color: NeumorphicTheme.primaryAccent,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
