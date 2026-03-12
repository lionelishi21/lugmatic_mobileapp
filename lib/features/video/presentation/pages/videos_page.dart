import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../../data/models/video_model.dart';
import '../../../../data/services/video_service.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({Key? key}) : super(key: key);

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  late VideoService _videoService;
  List<VideoModel> _videos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _videoService = context.read<VideoService>();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final videos = await _videoService.getFeedVideos();
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load videos';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Videos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVideos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _videos.isEmpty
                  ? const Center(
                      child: Text('No videos found',
                          style: TextStyle(color: Colors.white70)),
                    )
                  : PageView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: _videos.length,
                      itemBuilder: (context, index) {
                        return VideoPlayerItem(video: _videos[index]);
                      },
                    ),
    );
  }
}

class VideoPlayerItem extends StatefulWidget {
  final VideoModel video;
  const VideoPlayerItem({Key? key, required this.video}) : super(key: key);

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
    );

    await _videoPlayerController.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: true,
      showControls: true,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      placeholder: widget.video.thumbnailUrl.isNotEmpty
          ? Image.network(widget.video.thumbnailUrl, fit: BoxFit.cover)
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );

    if (mounted) setState(() {});
    
    // Increment view count
    context.read<VideoService>().incrementViews(widget.video.id);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_chewieController != null &&
            _chewieController!.videoPlayerController.value.isInitialized)
          Chewie(controller: _chewieController!)
        else
          const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
        
        // Overlay for Artist Info
        Positioned(
          left: 16,
          bottom: 32,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${widget.video.artistName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.video.title,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              if (widget.video.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.video.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
