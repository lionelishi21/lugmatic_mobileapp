import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/live_clash_model.dart';
import '../../../../data/services/live_stream_service.dart';
import '../../../../core/config/api_config.dart';
import '../../../regular_clash/regular_clash_feed_page.dart' show RegularClashTabContent;

class ClashesHubPage extends StatefulWidget {
  const ClashesHubPage({Key? key}) : super(key: key);

  @override
  State<ClashesHubPage> createState() => _ClashesHubPageState();
}

class _ClashesHubPageState extends State<ClashesHubPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late AnimationController _flameController;
  late LiveStreamService _liveStreamService;

  bool _isLoading = true;
  List<LiveClashModel> _liveClashes = [];
  List<LiveClashModel> _pastClashes = [];
  List<Map<String, dynamic>> _rankings = [];

  static const _kFire = Color(0xFFFF4D00);
  static const _kFireDim = Color(0xFFFF8C00);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _liveStreamService = LiveStreamService(apiClient: context.read());
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _flameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _liveStreamService.getRecentClashes(limit: 20),
        _liveStreamService
            .getClashRankings('all-time')
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (mounted) {
        setState(() {
          final all = results[0] as List<LiveClashModel>;
          _liveClashes = all.where((c) => c.status == 'active').toList();
          _pastClashes = all.where((c) => c.status == 'ended').toList();
          _rankings = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07080F),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [_buildSliverHeader()],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kFire))
            : TabBarView(
                controller: _tabController,
                children: [
                  _LiveClashTab(
                    clashes: _liveClashes,
                    pulseAnim: _pulseController,
                    flameAnim: _flameController,
                    onRefresh: _loadData,
                  ),
                  _PastClashTab(clashes: _pastClashes, onRefresh: _loadData),
                  _RankingsTab(rankings: _rankings),
                  const RegularClashTabContent(),
                ],
              ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 160,
      backgroundColor: const Color(0xFF07080F),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroHeader(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _buildTabBar(),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0505), Color(0xFF0F0A1A), Color(0xFF07080F)],
        ),
      ),
      child: Stack(
        children: [
          // Background spark particles (decorative)
          ...List.generate(12, (i) => _SparkDot(index: i, anim: _flameController)),
          // Title
          Positioned(
            bottom: 56,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [_kFire, _kFireDim, Colors.amber],
                      stops: [
                        0.0,
                        0.4 + 0.2 * _pulseController.value,
                        1.0,
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      '⚔ LYRICAL WARS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Artist battles. Real stakes. No mercy.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF07080F),
      child: TabBar(
        controller: _tabController,
        indicatorColor: _kFire,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white30,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_liveClashes.isNotEmpty)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent
                            .withValues(alpha: 0.4 + 0.6 * _pulseController.value),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                const Text('LIVE NOW'),
              ],
            ),
          ),
          const Tab(text: 'PAST'),
          const Tab(text: 'RANKINGS'),
          const Tab(text: 'REGULAR'),
        ],
      ),
    );
  }
}

// ── Spark dots (decorative background) ───────────────────────────────────────

class _SparkDot extends StatelessWidget {
  final int index;
  final AnimationController anim;
  _SparkDot({Key? key, required this.index, required this.anim}) : super(key: key);
  final _rng = Random(42);

  @override
  Widget build(BuildContext context) {
    final x = _rng.nextDouble() * 400;
    final y = _rng.nextDouble() * 160;
    final size = 2.0 + _rng.nextDouble() * 3;
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Positioned(
        left: x,
        top: y,
        child: Opacity(
          opacity: 0.1 + 0.3 * ((anim.value + index * 0.1) % 1.0),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: index.isEven ? const Color(0xFFFF4D00) : Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Live clash tab ────────────────────────────────────────────────────────────

class _LiveClashTab extends StatelessWidget {
  final List<LiveClashModel> clashes;
  final AnimationController pulseAnim;
  final AnimationController flameAnim;
  final Future<void> Function() onRefresh;

  const _LiveClashTab({
    Key? key,
    required this.clashes,
    required this.pulseAnim,
    required this.flameAnim,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (clashes.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: const Color(0xFFFF4D00),
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚔', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    const Text('No live battles right now',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Pull to refresh or check back soon',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFFF4D00),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: clashes.length,
        itemBuilder: (context, i) => _LiveClashCard(
          clash: clashes[i],
          pulseAnim: pulseAnim,
          flameAnim: flameAnim,
        ),
      ),
    );
  }
}

// ── Live clash card ───────────────────────────────────────────────────────────

class _LiveClashCard extends StatelessWidget {
  final LiveClashModel clash;
  final AnimationController pulseAnim;
  final AnimationController flameAnim;

  const _LiveClashCard({
    Key? key,
    required this.clash,
    required this.pulseAnim,
    required this.flameAnim,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = (clash.challengerScore + clash.opponentScore).clamp(1.0, double.infinity);
    final challengerPct = clash.challengerScore / total;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/live', arguments: clash.id),
      child: AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A0505),
                const Color(0xFF0F0A1A),
              ],
            ),
            border: Border.all(
              color: Color.lerp(
                    const Color(0xFFFF4D00).withValues(alpha: 0.5),
                    const Color(0xFFFF8C00).withValues(alpha: 0.8),
                    pulseAnim.value,
                  ) ??
                  const Color(0xFFFF4D00),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D00)
                    .withValues(alpha: 0.1 + 0.1 * pulseAnim.value),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with LIVE badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF4D00).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: pulseAnim,
                      builder: (_, __) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            const Color(0xFFFF4D00),
                            const Color(0xFFFF8C00),
                            pulseAnim.value,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_manual_record,
                                color: Colors.white, size: 8),
                            SizedBox(width: 4),
                            Text('LIVE',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      clash.realm.isNotEmpty ? clash.realm.toUpperCase() : 'LYRICAL WAR',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          letterSpacing: 1),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white30),
                  ],
                ),
              ),

              // Battle arena
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    // Artists face-off
                    Row(
                      children: [
                        Expanded(
                            child: _ArtistSide(
                          name: clash.challenger.name,
                          image: clash.challenger.image,
                          score: clash.challengerScore.toInt(),
                          isLeading: clash.challengerScore >= clash.opponentScore,
                          alignment: Alignment.centerLeft,
                        )),
                        // VS center
                        SizedBox(
                          width: 64,
                          child: Column(
                            children: [
                              AnimatedBuilder(
                                animation: flameAnim,
                                builder: (_, __) => Text(
                                  '⚔',
                                  style: TextStyle(
                                    fontSize: 24 + 4 * flameAnim.value,
                                  ),
                                ),
                              ),
                              const Text('VS',
                                  style: TextStyle(
                                      color: Colors.white24,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2)),
                            ],
                          ),
                        ),
                        Expanded(
                            child: _ArtistSide(
                          name: clash.opponent.name,
                          image: clash.opponent.image,
                          score: clash.opponentScore.toInt(),
                          isLeading: clash.opponentScore > clash.challengerScore,
                          alignment: Alignment.centerRight,
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Score battle bar
                    _BattleBar(
                        challengerPct: challengerPct,
                        challengerColor: const Color(0xFF10B981),
                        opponentColor: const Color(0xFFFF4D00)),

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(challengerPct * 100).round()}%',
                          style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '🔥 TAP TO JOIN BATTLE',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                              letterSpacing: 1),
                        ),
                        Text(
                          '${(100 - challengerPct * 100).round()}%',
                          style: const TextStyle(
                              color: Color(0xFFFF4D00),
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Artist side widget ────────────────────────────────────────────────────────

class _ArtistSide extends StatelessWidget {
  final String name;
  final String image;
  final int score;
  final bool isLeading;
  final Alignment alignment;

  const _ArtistSide({
    Key? key,
    required this.name,
    required this.image,
    required this.score,
    required this.isLeading,
    required this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isRight = alignment == Alignment.centerRight;
    return Column(
      crossAxisAlignment:
          isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: isRight ? Alignment.topRight : Alignment.topLeft,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white12,
              backgroundImage: image.isNotEmpty
                  ? NetworkImage(ApiConfig.resolveUrl(image))
                  : null,
              child: image.isEmpty
                  ? const Icon(Icons.person, color: Colors.white38, size: 32)
                  : null,
            ),
            if (isLeading)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD700),
                  shape: BoxShape.circle,
                ),
                child: const Text('👑', style: TextStyle(fontSize: 10)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: isRight ? TextAlign.right : TextAlign.left,
        ),
        const SizedBox(height: 4),
        Text(
          score.toString(),
          style: TextStyle(
            color: isLeading
                ? const Color(0xFF10B981)
                : Colors.white.withValues(alpha: 0.5),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ── Battle bar ────────────────────────────────────────────────────────────────

class _BattleBar extends StatelessWidget {
  final double challengerPct;
  final Color challengerColor;
  final Color opponentColor;

  const _BattleBar({
    Key? key,
    required this.challengerPct,
    required this.challengerColor,
    required this.opponentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Expanded(
              flex: (challengerPct * 100).round().clamp(1, 99),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [challengerColor, challengerColor.withValues(alpha: 0.7)],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: (100 - challengerPct * 100).round().clamp(1, 99),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [opponentColor.withValues(alpha: 0.7), opponentColor],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Past clash tab ────────────────────────────────────────────────────────────

class _PastClashTab extends StatelessWidget {
  final List<LiveClashModel> clashes;
  final Future<void> Function() onRefresh;

  const _PastClashTab({Key? key, required this.clashes, required this.onRefresh})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (clashes.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: const Color(0xFFFF4D00),
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📜', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    const Text('No past battles yet',
                        style: TextStyle(color: Colors.white54, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFFF4D00),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: clashes.length,
        itemBuilder: (context, i) => _PastClashCard(clash: clashes[i]),
      ),
    );
  }
}

class _PastClashCard extends StatelessWidget {
  final LiveClashModel clash;
  const _PastClashCard({Key? key, required this.clash}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final challengerWon = clash.challengerScore >= clash.opponentScore;
    final total =
        (clash.challengerScore + clash.opponentScore).clamp(1.0, double.infinity);
    final pct = clash.challengerScore / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _MiniArtist(
                name: clash.challenger.name,
                image: clash.challenger.image,
                isWinner: challengerWon,
                score: clash.challengerScore.toInt(),
                labelLeft: true,
              ),
              const Expanded(
                child: Center(
                  child: Text('⚔',
                      style: TextStyle(fontSize: 18, color: Colors.white24)),
                ),
              ),
              _MiniArtist(
                name: clash.opponent.name,
                image: clash.opponent.image,
                isWinner: !challengerWon,
                score: clash.opponentScore.toInt(),
                labelLeft: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BattleBar(
            challengerPct: pct,
            challengerColor: const Color(0xFF10B981),
            opponentColor: const Color(0xFFFF4D00),
          ),
          const SizedBox(height: 8),
          Text(
            clash.realm.toUpperCase(),
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 10,
                letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class _MiniArtist extends StatelessWidget {
  final String name;
  final String image;
  final bool isWinner;
  final int score;
  final bool labelLeft;

  const _MiniArtist({
    Key? key,
    required this.name,
    required this.image,
    required this.isWinner,
    required this.score,
    required this.labelLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          labelLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (labelLeft && isWinner)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text('👑', style: TextStyle(fontSize: 14)),
              ),
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white12,
              backgroundImage: image.isNotEmpty
                  ? NetworkImage(ApiConfig.resolveUrl(image))
                  : null,
              child: image.isEmpty
                  ? const Icon(Icons.person, color: Colors.white38, size: 18)
                  : null,
            ),
            if (!labelLeft && isWinner)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('👑', style: TextStyle(fontSize: 14)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(
          score.toString(),
          style: TextStyle(
              color: isWinner ? const Color(0xFFFFD700) : Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

// ── Rankings tab ──────────────────────────────────────────────────────────────

class _RankingsTab extends StatelessWidget {
  final List<Map<String, dynamic>> rankings;
  const _RankingsTab({Key? key, required this.rankings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏆', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text('No rankings yet', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );
    }

    final top3 = rankings.take(3).toList();
    final rest = rankings.skip(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        children: [
          // Podium
          _Podium(top3: top3),
          const SizedBox(height: 24),
          // Rest of list
          ...rest.asMap().entries.map((e) {
            final i = e.key + 3;
            final rank = e.value;
            final name = rank['name']?.toString() ?? 'Unknown';
            final image = rank['image']?.toString() ?? '';
            final score = rank['totalScore'] ?? 0;
            final count = rank['clashCount'] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      '#${i + 1}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white12,
                    backgroundImage: image.isNotEmpty
                        ? NetworkImage(ApiConfig.resolveUrl(image))
                        : null,
                    child: image.isEmpty
                        ? const Icon(Icons.person, color: Colors.white38, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('$count battles • $score pts',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(score.toString(),
                      style: const TextStyle(
                          color: Colors.white38, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Podium widget ─────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<Map<String, dynamic>> top3;
  const _Podium({Key? key, required this.top3}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Order: 2nd, 1st, 3rd
    final ordered = [
      if (top3.length > 1) MapEntry(1, top3[1]),
      if (top3.isNotEmpty) MapEntry(0, top3[0]),
      if (top3.length > 2) MapEntry(2, top3[2]),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: ordered.map((e) {
        final pos = e.key;
        final data = e.value;
        final heights = [120.0, 90.0, 70.0];
        final colors = [
          const Color(0xFFFFD700),
          const Color(0xFFB0B0B0),
          const Color(0xFFCD7F32),
        ];
        final emojis = ['🥇', '🥈', '🥉'];
        final h = pos < heights.length ? heights[pos] : 70.0;
        final color = pos < colors.length ? colors[pos] : Colors.white24;
        final emoji = pos < emojis.length ? emojis[pos] : '';
        final name = data['name']?.toString() ?? '';
        final image = data['image']?.toString() ?? '';
        final score = data['totalScore'] ?? 0;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              CircleAvatar(
                radius: pos == 0 ? 32 : 24,
                backgroundColor: color.withValues(alpha: 0.2),
                backgroundImage: image.isNotEmpty
                    ? NetworkImage(ApiConfig.resolveUrl(image))
                    : null,
                child: image.isEmpty
                    ? Icon(Icons.person, color: color, size: pos == 0 ? 28 : 20)
                    : null,
              ),
              const SizedBox(height: 6),
              Text(name,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: pos == 0 ? 14 : 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
              Text(score.toString(),
                  style: TextStyle(
                      color: color,
                      fontSize: pos == 0 ? 16 : 13,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Container(
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.15)],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Center(
                  child: Text(
                    '#${pos + 1}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
