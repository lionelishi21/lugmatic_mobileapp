import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/regular_clash_model.dart';
import '../../../data/services/regular_clash_service.dart';
import '../../regular_clash/regular_clash_detail_page.dart';

// ── realm helpers ──────────────────────────────────────────────────────────
Color _realmColor(String realm) {
  switch (realm.toLowerCase()) {
    case 'fire':   return const Color(0xFFFF4500);
    case 'water':  return const Color(0xFF00BFFF);
    case 'earth':  return const Color(0xFF7CFC00);
    case 'air':    return const Color(0xFFE0E0E0);
    default:       return AppColors.primary;
  }
}

String _realmEmoji(String realm) {
  switch (realm.toLowerCase()) {
    case 'fire':  return '🔥';
    case 'water': return '💧';
    case 'earth': return '🌍';
    case 'air':   return '💨';
    default:      return '⚡';
  }
}

// ── main screen ────────────────────────────────────────────────────────────
class ArtistClashesScreen extends StatefulWidget {
  const ArtistClashesScreen({super.key});

  @override
  State<ArtistClashesScreen> createState() => _ArtistClashesScreenState();
}

class _ArtistClashesScreenState extends State<ArtistClashesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseCtrl;
  late RegularClashService _service;

  List<RegularClashModel> _incoming = [];
  List<RegularClashModel> _active = [];
  List<RegularClashModel> _past = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _service = RegularClashService(apiClient: context.read());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getIncomingChallenges(),
        _service.getMyClashes(),
      ]);
      if (!mounted) return;
      final incoming = results[0];
      final mine = results[1];
      setState(() {
        _incoming = incoming;
        _active = mine.where((c) => c.status == 'active' || c.status == 'voting').toList();
        _past = mine.where((c) => c.status == 'ended' || c.status == 'rejected').toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  int get _wins => _past.where((c) => c.winner != null && c.status == 'ended').length;
  int get _losses => _past.where((c) => c.winner == null && c.status == 'ended').length;

  @override
  void dispose() {
    _tabController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [_buildSliverHeader()],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _buildErrorState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildIncomingTab(),
                      _buildActiveTab(),
                      _buildPastTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A0F),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            '/artist/regular-clash/challenge',
          ).then((_) => _loadData()),
          icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 18),
          label: const Text('Challenge',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeaderBackground(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: const Color(0xFF0A0A0F),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: [
              Tab(text: 'Incoming${_incoming.isNotEmpty ? " (${_incoming.length})" : ""}'),
              const Tab(text: 'Active'),
              const Tab(text: 'Past'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A2E), Color(0xFF0A0A0F)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30, left: -30,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withOpacity(0.08 + _pulseCtrl.value * 0.06),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Text(
                          '⚡',
                          style: TextStyle(fontSize: 28 + _pulseCtrl.value * 3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'My Clashes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_isLoading && _error == null)
                    Row(
                      children: [
                        _StatChip(label: 'Wins', value: '$_wins', color: AppColors.primary),
                        const SizedBox(width: 10),
                        _StatChip(label: 'Losses', value: '$_losses', color: Colors.redAccent),
                        const SizedBox(width: 10),
                        _StatChip(label: 'Active', value: '${_active.length}', color: Colors.amber),
                        const SizedBox(width: 10),
                        _StatChip(label: 'Pending', value: '${_incoming.length}', color: Colors.purpleAccent),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingTab() {
    if (_incoming.isEmpty) {
      return _EmptyState(
        icon: Icons.mail_outline,
        title: 'No Incoming Challenges',
        subtitle: 'When artists challenge you, they\'ll appear here.',
        actionLabel: 'Challenge Someone',
        onAction: () => Navigator.pushNamed(context, '/artist/regular-clash/challenge').then((_) => _loadData()),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _incoming.length,
        itemBuilder: (context, i) => _IncomingCard(
          clash: _incoming[i],
          service: _service,
          onAction: _loadData,
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_active.isEmpty) {
      return _EmptyState(
        icon: Icons.local_fire_department,
        title: 'No Active Clashes',
        subtitle: 'Accept a challenge or start one to begin battling.',
        actionLabel: 'Start a Clash',
        onAction: () => Navigator.pushNamed(context, '/artist/regular-clash/challenge').then((_) => _loadData()),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _active.length,
        itemBuilder: (context, i) => _ActiveCard(
          clash: _active[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegularClashDetailPage(clashId: _active[i].id, initialData: _active[i]),
            ),
          ).then((_) => _loadData()),
          onUploadVideo: () => Navigator.pushNamed(
            context,
            '/artist/record-clash-video',
            arguments: {'clashId': _active[i].id},
          ).then((_) => _loadData()),
        ),
      ),
    );
  }

  Widget _buildPastTab() {
    if (_past.isEmpty) {
      return const _EmptyState(
        icon: Icons.history,
        title: 'No Past Clashes',
        subtitle: 'Your clash history will appear here.',
      );
    }
    final wins = _past.where((c) => c.winner != null && c.status == 'ended').length;
    final total = _past.where((c) => c.status == 'ended').length;
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _past.length + (total > 0 ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == 0 && total > 0) return _RecordBanner(wins: wins, total: total);
          final idx = total > 0 ? i - 1 : i;
          return _PastCard(
            clash: _past[idx],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RegularClashDetailPage(clashId: _past[idx].id, initialData: _past[idx]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── stat chip ──────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
        ],
      ),
    );
  }
}

// ── record banner ─────────────────────────────────────────────────────────
class _RecordBanner extends StatelessWidget {
  final int wins, total;
  const _RecordBanner({required this.wins, required this.total});

  @override
  Widget build(BuildContext context) {
    final winRate = total == 0 ? 0.0 : wins / total;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.15), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$wins–${total - wins} Record',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: winRate,
                    backgroundColor: Colors.white12,
                    color: AppColors.primary,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(winRate * 100).round()}%',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

// ── empty state ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
              child: Icon(icon, size: 40, color: Colors.white24),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 13), textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── incoming challenge card ────────────────────────────────────────────────
class _IncomingCard extends StatefulWidget {
  final RegularClashModel clash;
  final RegularClashService service;
  final VoidCallback onAction;

  const _IncomingCard({required this.clash, required this.service, required this.onAction});

  @override
  State<_IncomingCard> createState() => _IncomingCardState();
}

class _IncomingCardState extends State<_IncomingCard> with SingleTickerProviderStateMixin {
  bool _isActing = false;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    setState(() => _isActing = true);
    try {
      await widget.service.acceptChallenge(widget.clash.id);
      widget.onAction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isActing = false);
      }
    }
  }

  Future<void> _reject() async {
    setState(() => _isActing = true);
    try {
      await widget.service.rejectChallenge(widget.clash.id);
      widget.onAction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isActing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clash = widget.clash;
    final rc = _realmColor(clash.realm);

    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, child) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              rc.withOpacity(0.15 + math.sin(_shimmerCtrl.value * math.pi) * 0.05),
              const Color(0xFF1A1A2E),
            ],
          ),
          border: Border.all(color: rc.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: rc.withOpacity(0.2 + math.sin(_shimmerCtrl.value * math.pi) * 0.1),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _AvatarRing(image: widget.clash.challenger.image, radius: 28, ringColor: _realmColor(widget.clash.realm)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              clash.challenger.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _realmColor(clash.realm).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_realmEmoji(clash.realm)} ${clash.realm.toUpperCase()}',
                              style: TextStyle(color: _realmColor(clash.realm), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'is challenging you to a clash!',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (clash.message != null && clash.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote, color: Colors.white38, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        clash.message!,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_isActing)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reject,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        foregroundColor: Colors.white54,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _accept,
                      icon: const Icon(Icons.flash_on, size: 16),
                      label: const Text('Accept Battle', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _realmColor(clash.realm),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── active clash card ──────────────────────────────────────────────────────
class _ActiveCard extends StatelessWidget {
  final RegularClashModel clash;
  final VoidCallback onTap;
  final VoidCallback onUploadVideo;

  const _ActiveCard({required this.clash, required this.onTap, required this.onUploadVideo});

  @override
  Widget build(BuildContext context) {
    final cSubmitted = clash.challengerVideo?.isSubmitted ?? false;
    final oSubmitted = clash.opponentVideo?.isSubmitted ?? false;
    final isVoting = clash.status == 'voting';
    final total = clash.totalVotes;
    final cPct = clash.challengerVotePercent;
    final rc = _realmColor(clash.realm);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF141420),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isVoting ? rc.withOpacity(0.5) : Colors.white12,
            width: isVoting ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [rc.withOpacity(0.15), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Text('${_realmEmoji(clash.realm)} ${clash.realm.toUpperCase()}',
                      style: TextStyle(color: rc, fontSize: 11, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isVoting ? rc.withOpacity(0.2) : Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isVoting ? '🗳 VOTING' : '⚔️ ACTIVE',
                      style: TextStyle(
                        color: isVoting ? rc : Colors.white54,
                        fontSize: 10, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _AvatarRing(image: clash.challenger.image, radius: 26, ringColor: rc),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, fontSize: 14)),
                            if (isVoting && total > 0) ...[
                              const SizedBox(height: 4),
                              _BattleBar(cPct: cPct, color: rc),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${(cPct * 100).round()}%',
                                      style: TextStyle(color: rc, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('$total votes', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                  Text('${((1 - cPct) * 100).round()}%',
                                      style: TextStyle(color: Colors.deepOrangeAccent.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      _AvatarRing(image: clash.opponent.image, radius: 26, ringColor: Colors.deepOrangeAccent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(clash.challenger.name,
                            style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        child: Text(clash.opponent.name,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _SlotBadge(label: 'Your Clip', submitted: cSubmitted, color: rc),
                      const SizedBox(width: 8),
                      _SlotBadge(label: 'Opponent Clip', submitted: oSubmitted, color: Colors.deepOrangeAccent),
                    ],
                  ),
                  if (!cSubmitted && clash.status == 'active') ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onUploadVideo,
                        icon: const Icon(Icons.videocam, size: 18),
                        label: const Text('Record 60-sec Clip', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rc,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleBar extends StatelessWidget {
  final double cPct;
  final Color color;

  const _BattleBar({required this.cPct, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(color: Colors.deepOrangeAccent.withOpacity(0.4)),
            FractionallySizedBox(
              widthFactor: cPct,
              child: Container(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotBadge extends StatelessWidget {
  final String label;
  final bool submitted;
  final Color color;

  const _SlotBadge({required this.label, required this.submitted, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: submitted ? color.withOpacity(0.12) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: submitted ? color.withOpacity(0.35) : Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            submitted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 12,
            color: submitted ? color : Colors.white24,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: submitted ? color : Colors.white38, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── past clash card ────────────────────────────────────────────────────────
class _PastCard extends StatelessWidget {
  final RegularClashModel clash;
  final VoidCallback onTap;

  const _PastCard({required this.clash, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRejected = clash.status == 'rejected';
    final hasWinner = clash.winner != null;
    final total = clash.totalVotes;
    final cPct = clash.challengerVotePercent;
    final rc = _realmColor(clash.realm);

    Color outcomeColor;
    String outcomeLabel;
    IconData outcomeIcon;

    if (isRejected) {
      outcomeColor = Colors.white38;
      outcomeLabel = 'Declined';
      outcomeIcon = Icons.block;
    } else if (!hasWinner) {
      outcomeColor = Colors.white38;
      outcomeLabel = 'Draw';
      outcomeIcon = Icons.handshake_outlined;
    } else {
      outcomeColor = Colors.amber;
      outcomeLabel = '${clash.winner!.name.split(' ').first} Won';
      outcomeIcon = Icons.emoji_events;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111118),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text('${_realmEmoji(clash.realm)} ${clash.realm}',
                    style: TextStyle(color: rc.withOpacity(0.7), fontSize: 11)),
                const Spacer(),
                Icon(outcomeIcon, size: 14, color: outcomeColor),
                const SizedBox(width: 4),
                Text(outcomeLabel, style: TextStyle(color: outcomeColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _AvatarRing(image: clash.challenger.image, radius: 20, ringColor: rc),
                const SizedBox(width: 8),
                Expanded(
                  child: !isRejected && total > 0
                      ? Column(
                          children: [
                            _BattleBar(cPct: cPct, color: rc),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${clash.challengerVotes}v',
                                    style: TextStyle(color: rc.withOpacity(0.8), fontSize: 10)),
                                Text('$total total', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                Text('${clash.opponentVotes}v',
                                    style: TextStyle(color: Colors.deepOrangeAccent.withOpacity(0.7), fontSize: 10)),
                              ],
                            ),
                          ],
                        )
                      : const Center(child: Text('—', style: TextStyle(color: Colors.white24))),
                ),
                const SizedBox(width: 8),
                _AvatarRing(image: clash.opponent.image, radius: 20, ringColor: Colors.deepOrangeAccent),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(clash.challenger.name,
                      style: const TextStyle(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: Text(clash.opponent.name,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── avatar with ring ───────────────────────────────────────────────────────
class _AvatarRing extends StatelessWidget {
  final String? image;
  final double radius;
  final Color ringColor;

  const _AvatarRing({required this.image, required this.radius, required this.ringColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor.withOpacity(0.6), width: 2),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white12,
        backgroundImage: image != null ? NetworkImage(ApiConfig.resolveUrl(image!)) : null,
        child: image == null ? Icon(Icons.person, color: Colors.white38, size: radius * 0.8) : null,
      ),
    );
  }
}
