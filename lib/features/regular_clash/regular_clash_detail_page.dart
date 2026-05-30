import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/regular_clash_model.dart';
import '../../data/services/regular_clash_service.dart';

enum _Phase { idle, challenger, transition, opponent, done }

class RegularClashDetailPage extends StatefulWidget {
  final String clashId;
  final RegularClashModel? initialData;

  const RegularClashDetailPage({super.key, required this.clashId, this.initialData});

  @override
  State<RegularClashDetailPage> createState() => _RegularClashDetailPageState();
}

class _RegularClashDetailPageState extends State<RegularClashDetailPage> {
  late RegularClashService _service;
  RegularClashModel? _clash;
  bool _isLoading = true;
  String? _error;

  _Phase _phase = _Phase.idle;
  VideoPlayerController? _videoController;
  bool _isVideoLoading = false;
  Timer? _transitionTimer;

  bool _hasVoted = false;
  bool _isVoting = false;
  bool _isLiked = false;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _service = RegularClashService(apiClient: context.read());
    _clash = widget.initialData;
    if (_clash != null) {
      _isLoading = false;
    } else {
      _loadClash();
    }
  }

  Future<void> _loadClash() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final clash = await _service.getClash(widget.clashId);
      if (mounted) setState(() { _clash = clash; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _startPlayback() async {
    final clash = _clash;
    if (clash == null || !clash.bothVideosSubmitted) return;
    setState(() { _phase = _Phase.challenger; _isVideoLoading = true; });
    await _playVideo(clash.challengerVideo!.videoUrl!);
  }

  Future<void> _playVideo(String url) async {
    final resolvedUrl = url.startsWith('http') ? url : ApiConfig.resolveUrl(url);
    await _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl));
    await _videoController!.initialize();
    _videoController!.addListener(_onVideoEvent);
    if (mounted) {
      setState(() => _isVideoLoading = false);
      _videoController!.play();
    }
  }

  void _onVideoEvent() {
    if (_videoController == null) return;
    final pos = _videoController!.value.position;
    final dur = _videoController!.value.duration;
    if (dur.inMilliseconds > 0 && pos >= dur - const Duration(milliseconds: 200)) {
      _videoController!.removeListener(_onVideoEvent);
      _onVideoEnded();
    }
  }

  void _onVideoEnded() {
    if (!mounted) return;
    if (_phase == _Phase.challenger) {
      setState(() => _phase = _Phase.transition);
      _transitionTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() { _phase = _Phase.opponent; _isVideoLoading = true; });
        _playVideo(_clash!.opponentVideo!.videoUrl!);
      });
    } else if (_phase == _Phase.opponent) {
      setState(() => _phase = _Phase.done);
    }
  }

  Future<void> _vote(String side) async {
    if (_isVoting || _hasVoted) return;
    setState(() => _isVoting = true);
    try {
      await _service.vote(widget.clashId, side);
      if (mounted) setState(() { _hasVoted = true; _isVoting = false; });
      _showSnackBar('Vote cast!');
    } catch (e) {
      if (mounted) setState(() => _isVoting = false);
      _showSnackBar('Failed to vote: $e');
    }
  }

  Future<void> _like() async {
    if (_isLiking) return;
    setState(() => _isLiking = true);
    try {
      await _service.like(widget.clashId);
      if (mounted) setState(() { _isLiked = !_isLiked; _isLiking = false; });
    } catch (_) {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          TextButton(onPressed: _loadClash, child: const Text('Retry', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final clash = _clash!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _RealmBadge(realm: clash.realm),
          const SizedBox(height: 16),
          _ArtistVsRow(
            challenger: clash.challenger,
            opponent: clash.opponent,
            winner: clash.winner,
          ),
          const SizedBox(height: 20),
          _buildVideoSection(clash),
          const SizedBox(height: 20),
          if (_phase == _Phase.done || clash.isEnded) _buildVoteSection(clash),
          const SizedBox(height: 16),
          _buildVoteBar(clash),
          const SizedBox(height: 20),
          _buildActions(clash),
        ],
      ),
    );
  }

  Widget _buildVideoSection(RegularClashModel clash) {
    if (!clash.bothVideosSubmitted) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('Videos not yet submitted', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_videoController != null && _videoController!.value.isInitialized && !_isVideoLoading)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                )
              else if (_isVideoLoading)
                const CircularProgressIndicator(color: AppColors.primary)
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_outline, color: Colors.white54, size: 64),
                    const SizedBox(height: 8),
                    const Text('Tap to watch', style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _startPlayback,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Watch Clash'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                    ),
                  ],
                ),
              if (_phase != _Phase.idle) _buildPhaseOverlay(),
            ],
          ),
        ),
        if (_phase == _Phase.idle && clash.bothVideosSubmitted)
          const SizedBox.shrink()
        else if (_phase != _Phase.done)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildPhaseLabel(clash),
          ),
      ],
    );
  }

  Widget _buildPhaseOverlay() {
    String label = '';
    if (_phase == _Phase.challenger) label = 'Round 1';
    if (_phase == _Phase.transition) label = 'Up next...';
    if (_phase == _Phase.opponent) label = 'Round 2';
    if (_phase == _Phase.done) label = 'Cast your vote';

    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildPhaseLabel(RegularClashModel clash) {
    String label = '';
    if (_phase == _Phase.challenger) label = 'Watching: ${clash.challenger.name}';
    if (_phase == _Phase.transition) label = 'Up next: ${clash.opponent.name}';
    if (_phase == _Phase.opponent) label = 'Watching: ${clash.opponent.name}';
    return Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13));
  }

  Widget _buildVoteSection(RegularClashModel clash) {
    final canVote = !_hasVoted && clash.isVoting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _hasVoted ? 'You voted!' : clash.isEnded ? 'Clash Ended' : 'Cast your vote',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _VoteButton(
                label: clash.challenger.name,
                side: 'challenger',
                onVote: canVote ? _vote : null,
                isVoting: _isVoting,
                isWinner: clash.winner?.id == clash.challenger.id,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VoteButton(
                label: clash.opponent.name,
                side: 'opponent',
                onVote: canVote ? _vote : null,
                isVoting: _isVoting,
                isWinner: clash.winner?.id == clash.opponent.id,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoteBar(RegularClashModel clash) {
    final pct = clash.challengerVotePercent;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${clash.challengerVotes} votes', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            Text('${clash.opponentVotes} votes', style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 6,
            width: double.infinity,
            color: AppColors.secondary,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct,
              child: Container(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(RegularClashModel clash) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _isLiking ? null : _like,
          icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : Colors.white54),
        ),
        Text('${clash.likesCount + (_isLiked ? 1 : 0)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(width: 24),
        IconButton(
          onPressed: () {
            // Share functionality
          },
          icon: const Icon(Icons.share, color: Colors.white54),
        ),
      ],
    );
  }
}

class _RealmBadge extends StatelessWidget {
  final String realm;
  const _RealmBadge({required this.realm});

  static const _realmColors = {
    'fire': Color(0xFFFF4500),
    'ice': Color(0xFF00BFFF),
    'reggae': Color(0xFF00C853),
    'dancehall': Color(0xFFFFD700),
    'hiphop': Color(0xFF9C27B0),
    'rnb': Color(0xFFE91E63),
    'afrobeats': Color(0xFFFF9800),
  };

  @override
  Widget build(BuildContext context) {
    final color = _realmColors[realm] ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        realm.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
      ),
    );
  }
}

class _ArtistVsRow extends StatelessWidget {
  final RegularClashArtist challenger;
  final RegularClashArtist opponent;
  final RegularClashArtist? winner;

  const _ArtistVsRow({required this.challenger, required this.opponent, this.winner});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ArtistInfo(artist: challenger, isWinner: winner?.id == challenger.id),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('VS', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w900, fontSize: 18)),
        ),
        _ArtistInfo(artist: opponent, isWinner: winner?.id == opponent.id),
      ],
    );
  }
}

class _ArtistInfo extends StatelessWidget {
  final RegularClashArtist artist;
  final bool isWinner;

  const _ArtistInfo({required this.artist, this.isWinner = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.muted,
              backgroundImage: artist.image != null ? NetworkImage(ApiConfig.resolveUrl(artist.image)) : null,
              child: artist.image == null ? const Icon(Icons.person, color: Colors.white54) : null,
            ),
            if (isWinner)
              const Positioned(
                top: 0, right: 0,
                child: Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          artist.name,
          style: TextStyle(
            color: isWinner ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _VoteButton extends StatelessWidget {
  final String label;
  final String side;
  final Function(String)? onVote;
  final bool isVoting;
  final bool isWinner;

  const _VoteButton({
    required this.label,
    required this.side,
    this.onVote,
    this.isVoting = false,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = side == 'challenger' ? AppColors.primary : AppColors.secondary;
    final canVote = onVote != null;

    return GestureDetector(
      onTap: canVote ? () => onVote!(side) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: canVote ? color.withOpacity(0.15) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWinner ? Colors.amber : (canVote ? color.withOpacity(0.5) : AppColors.border),
            width: isWinner ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (isVoting)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            else
              Icon(
                isWinner ? Icons.emoji_events : Icons.how_to_vote_outlined,
                color: isWinner ? Colors.amber : (canVote ? color : Colors.white38),
                size: 20,
              ),
            const SizedBox(height: 6),
            Text(
              canVote ? 'Vote ${label.split(' ').first}' : label,
              style: TextStyle(
                color: isWinner ? Colors.amber : (canVote ? color : Colors.white54),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
