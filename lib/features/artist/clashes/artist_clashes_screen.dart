import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/regular_clash_model.dart';
import '../../../data/services/regular_clash_service.dart';
import '../../regular_clash/regular_clash_detail_page.dart';

class ArtistClashesScreen extends StatefulWidget {
  const ArtistClashesScreen({super.key});

  @override
  State<ArtistClashesScreen> createState() => _ArtistClashesScreenState();
}

class _ArtistClashesScreenState extends State<ArtistClashesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
      if (mounted) {
        final incoming = results[0];
        final mine = results[1];
        setState(() {
          _incoming = incoming;
          _active = mine.where((c) => c.status == 'active' || c.status == 'voting').toList();
          _past = mine.where((c) => c.status == 'ended' || c.status == 'rejected').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('⚡ My Clashes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/artist/regular-clash/challenge').then((_) => _loadData()),
            icon: const Icon(Icons.add, color: AppColors.primary),
            label: const Text('Challenge', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: TabBar(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIncomingList(),
                    _buildActiveList(),
                    _buildPastList(),
                  ],
                ),
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

  Widget _buildEmptyState(String message, {IconData icon = Icons.sports_kabaddi}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildIncomingList() {
    if (_incoming.isEmpty) {
      return _buildEmptyState('No incoming challenges', icon: Icons.mail_outline);
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _incoming.length,
        itemBuilder: (context, i) => _IncomingCard(
          clash: _incoming[i],
          service: _service,
          onAction: _loadData,
        ),
      ),
    );
  }

  Widget _buildActiveList() {
    if (_active.isEmpty) {
      return _buildEmptyState('No active clashes');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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

  Widget _buildPastList() {
    if (_past.isEmpty) {
      return _buildEmptyState('No past clashes', icon: Icons.history);
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _past.length,
        itemBuilder: (context, i) => _PastCard(
          clash: _past[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegularClashDetailPage(clashId: _past[i].id, initialData: _past[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomingCard extends StatefulWidget {
  final RegularClashModel clash;
  final RegularClashService service;
  final VoidCallback onAction;

  const _IncomingCard({required this.clash, required this.service, required this.onAction});

  @override
  State<_IncomingCard> createState() => _IncomingCardState();
}

class _IncomingCardState extends State<_IncomingCard> {
  bool _isActing = false;

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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.muted,
                backgroundImage: clash.challenger.image != null
                    ? NetworkImage(ApiConfig.resolveUrl(clash.challenger.image))
                    : null,
                child: clash.challenger.image == null ? const Icon(Icons.person, color: Colors.white54) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clash.challenger.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('challenged you • ${clash.realm.toUpperCase()}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          if (clash.message != null && clash.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(8)),
              child: Text(clash.message!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 14),
          if (_isActing)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reject,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      foregroundColor: Colors.white54,
                    ),
                    child: const Text('Ignore'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _accept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final RegularClashModel clash;
  final VoidCallback onTap;
  final VoidCallback onUploadVideo;

  const _ActiveCard({required this.clash, required this.onTap, required this.onUploadVideo});

  @override
  Widget build(BuildContext context) {
    final cSubmitted = clash.challengerVideo?.isSubmitted ?? false;
    final oSubmitted = clash.opponentVideo?.isSubmitted ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: clash.status == 'voting' ? AppColors.primary.withOpacity(0.4) : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.muted,
                  backgroundImage: clash.opponent.image != null
                      ? NetworkImage(ApiConfig.resolveUrl(clash.opponent.image))
                      : null,
                  child: clash.opponent.image == null ? const Icon(Icons.person, color: Colors.white54, size: 16) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('vs ${clash.opponent.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: clash.status == 'voting' ? AppColors.primary.withOpacity(0.2) : AppColors.muted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    clash.status == 'voting' ? 'VOTING' : 'ACTIVE',
                    style: TextStyle(
                      color: clash.status == 'voting' ? AppColors.primary : Colors.white54,
                      fontSize: 10, fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _VideoSlotBadge(label: 'Your video', submitted: cSubmitted),
                const SizedBox(width: 8),
                _VideoSlotBadge(label: 'Opponent video', submitted: oSubmitted),
              ],
            ),
            if (!cSubmitted && clash.status == 'active') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onUploadVideo,
                  icon: const Icon(Icons.videocam, size: 18),
                  label: const Text('Record 6-sec clip', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoSlotBadge extends StatelessWidget {
  final String label;
  final bool submitted;

  const _VideoSlotBadge({required this.label, required this.submitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: submitted ? AppColors.primary.withOpacity(0.15) : AppColors.muted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: submitted ? AppColors.primary.withOpacity(0.4) : Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(submitted ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 12, color: submitted ? AppColors.primary : Colors.white38),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: submitted ? AppColors.primary : Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

class _PastCard extends StatelessWidget {
  final RegularClashModel clash;
  final VoidCallback onTap;

  const _PastCard({required this.clash, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isWinner = clash.winner != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.muted,
              backgroundImage: clash.opponent.image != null
                  ? NetworkImage(ApiConfig.resolveUrl(clash.opponent.image))
                  : null,
              child: clash.opponent.image == null ? const Icon(Icons.person, color: Colors.white54) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('vs ${clash.opponent.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('${clash.challengerVotes} : ${clash.opponentVotes} votes', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            if (isWinner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      clash.winner!.name.split(' ').first,
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              )
            else if (clash.status == 'rejected')
              const Text('Rejected', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
