import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lugmatic_flutter/core/network/api_client.dart';
import 'package:lugmatic_flutter/data/models/live_stream_model.dart';
import 'package:lugmatic_flutter/data/services/live_stream_service.dart';
import 'package:lugmatic_flutter/core/theme/neumorphic_theme.dart';
import 'package:intl/intl.dart';
// import 'package:chewie/chewie.dart'; // Assume chewie is used for VOD
import 'package:video_player/video_player.dart';

class RecordedStreamsPage extends StatefulWidget {
  const RecordedStreamsPage({super.key});

  @override
  State<RecordedStreamsPage> createState() => _RecordedStreamsPageState();
}

class _RecordedStreamsPageState extends State<RecordedStreamsPage> {
  late LiveStreamService _liveStreamService;
  List<LiveStreamModel> _recordedStreams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  void _initService() {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    _liveStreamService = LiveStreamService(apiClient: apiClient);
    _fetchRecordedStreams();
  }

  Future<void> _fetchRecordedStreams() async {
    try {
      final streams = await _liveStreamService.getRecordedStreams();
      if (mounted) {
        setState(() {
          _recordedStreams = streams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Past Streams', 
          style: TextStyle(fontWeight: FontWeight.bold, color: NeumorphicTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: NeumorphicTheme.primaryAccent));
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
    }

    if (_recordedStreams.isEmpty) {
      return const Center(child: Text('No recorded streams found', style: TextStyle(color: NeumorphicTheme.textTertiary)));
    }

    return RefreshIndicator(
      onRefresh: _fetchRecordedStreams,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _recordedStreams.length,
        itemBuilder: (context, index) {
          return _buildStreamCard(_recordedStreams[index]);
        },
      ),
    );
  }

  Widget _buildStreamCard(LiveStreamModel stream) {
    return GestureDetector(
      onTap: () => _playRecording(stream),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                // Thumbnail
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(stream.coverImage.isNotEmpty ? stream.coverImage : (stream.host?.image ?? '')),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                // Play Icon Overlay
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                  ),
                ),
                // Duration Overlay
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDuration(stream.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stream.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: NeumorphicTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            stream.host?.name ?? 'Unknown Artist',
            style: const TextStyle(color: NeumorphicTheme.textTertiary, fontSize: 12),
          ),
          Text(
            stream.endTime != null ? DateFormat.yMMMd().format(stream.endTime!) : '',
            style: TextStyle(color: NeumorphicTheme.textTertiary.withOpacity(0.5), fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _playRecording(LiveStreamModel stream) {
    if (stream.recordingUrl == null || stream.recordingUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recording available for this stream')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamReplayPage(stream: stream),
      ),
    );
  }
}

class LiveStreamReplayPage extends StatefulWidget {
  final LiveStreamModel stream;
  const LiveStreamReplayPage({super.key, required this.stream});

  @override
  State<LiveStreamReplayPage> createState() => _LiveStreamReplayPageState();
}

class _LiveStreamReplayPageState extends State<LiveStreamReplayPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.stream.recordingUrl!))
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        _controller.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.stream.title),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: _initialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller),
                    VideoProgressIndicator(_controller, allowScrubbing: true),
                    _buildPlayPauseOverlay(),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildPlayPauseOverlay() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 50),
      reverseDuration: const Duration(milliseconds: 200),
      child: _controller.value.isPlaying
          ? const SizedBox.shrink()
          : Container(
              color: Colors.black26,
              child: const Center(
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 100.0,
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
