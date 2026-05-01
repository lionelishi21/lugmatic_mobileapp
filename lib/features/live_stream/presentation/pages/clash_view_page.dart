import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lugmatic_flutter/core/config/api_config.dart';
import 'package:lugmatic_flutter/core/network/api_client.dart';
import 'package:lugmatic_flutter/data/services/live_stream_service.dart';
import 'package:lugmatic_flutter/data/services/socket_service.dart';
import 'package:lugmatic_flutter/data/models/live_clash_model.dart';
import 'package:lugmatic_flutter/data/models/live_stream_model.dart';
import 'package:lugmatic_flutter/features/live_stream/presentation/widgets/clash_video_widget.dart';
import 'package:lugmatic_flutter/features/live_stream/presentation/widgets/battle_bar_widget.dart';
import 'package:lugmatic_flutter/core/network/token_storage.dart';

/// Full-screen clash viewer opened when any fan taps the global clash notification.
/// Fetches the clash room token and shows the split-screen video immediately.
class ClashViewPage extends StatefulWidget {
  final String clashId;
  final String challengerName;
  final String opponentName;

  const ClashViewPage({
    super.key,
    required this.clashId,
    required this.challengerName,
    required this.opponentName,
  });

  @override
  State<ClashViewPage> createState() => _ClashViewPageState();
}

class _ClashViewPageState extends State<ClashViewPage> {
  LiveStreamTokenData? _clashTokenData;
  LiveClashModel? _clash;
  bool _loading = true;
  String? _error;

  late final LiveStreamService _liveStreamService;
  late final SocketService _socketService;
  StreamSubscription? _scoreSub;
  StreamSubscription? _endedSub;

  @override
  void initState() {
    super.initState();
    _liveStreamService = LiveStreamService(apiClient: context.read<ApiClient>());
    _socketService = SocketService.getInstance(tokenStorage: context.read<TokenStorage>());
    _load();
    _setupListeners();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _liveStreamService.getClashDetails(widget.clashId),
        _liveStreamService.getClashToken(widget.clashId),
      ]);

      final clash = results[0] as LiveClashModel;
      final tokenMap = results[1] as Map<String, dynamic>;

      if (!mounted) return;

      if (clash.status != 'active') {
        setState(() { _error = 'This clash is no longer active'; _loading = false; });
        return;
      }

      setState(() {
        _clash = clash;
        _clashTokenData = LiveStreamTokenData.fromJson(tokenMap);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load clash: $e'; _loading = false; });
    }
  }

  void _setupListeners() {
    _scoreSub = _socketService.onClashScoreUpdate.listen((data) {
      if (mounted && _clash != null) {
        setState(() {
          _clash = _clash!.copyWith(
            challengerScore: (data['challengerScore'] ?? 0).toDouble(),
            opponentScore: (data['opponentScore'] ?? 0).toDouble(),
          );
        });
      }
    });

    _endedSub = _socketService.onClashEnded.listen((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The clash has ended!')),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    });
  }

  @override
  void dispose() {
    _scoreSub?.cancel();
    _endedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _error != null
                ? _buildError()
                : _buildClashView(),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.sports_kabaddi, color: Colors.white24, size: 64),
        const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Go Back', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  Widget _buildClashView() {
    final clash = _clash!;
    final token = _clashTokenData!;

    return Stack(
      children: [
        // Full-screen split-screen video
        Positioned.fill(
          child: ClashVideoWidget(
            tokenData: token,
            challengerId: clash.challengerUserId ?? clash.challenger.id,
            opponentId: clash.opponentUserId ?? clash.opponent.id,
            isHost: false,
          ),
        ),

        // Back button
        Positioned(
          top: 12, left: 12,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.black45),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        // Score bar at top
        Positioned(
          top: 12, left: 60, right: 12,
          child: BattleBarWidget(
            challengerScore: clash.challengerScore,
            opponentScore: clash.opponentScore,
            challengerName: clash.challenger.name,
            opponentName: clash.opponent.name,
            durationSeconds: clash.duration,
            startTime: clash.startTime,
          ),
        ),
      ],
    );
  }
}
