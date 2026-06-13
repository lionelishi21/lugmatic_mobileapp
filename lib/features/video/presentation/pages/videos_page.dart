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

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
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
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 120, 16, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _videos.length,
                      itemBuilder: (context, index) {
                        final video = _videos[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(video: video),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                video.thumbnailUrl.isNotEmpty
                                    ? Image.network(video.thumbnailUrl, fit: BoxFit.cover)
                                    : Container(color: Colors.grey[900]),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                ),
                                const Center(
                                  child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        video.title,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        video.artistName,
                                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (video.description.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          video.description,
                                          style: const TextStyle(color: Colors.white60, fontSize: 9),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.play_arrow, color: Colors.white70, size: 12),
                                          const SizedBox(width: 2),
                                          Text(
                                            _formatCount(video.views),
                                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.favorite, color: Colors.white70, size: 12),
                                          const SizedBox(width: 2),
                                          Text(
                                            _formatCount(video.likesCount),
                                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  const VideoPlayerScreen({Key? key, required this.video}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
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
      autoPlay: false, // Disabled autoplay per user request
      looping: true,
      showControls: true,
      autoInitialize: true,
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(widget.video.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _chewieController != null &&
                      _chewieController!.videoPlayerController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.video.artistName,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.play_arrow, color: Colors.white54, size: 16),
                    const SizedBox(width: 4),
                    Text('${widget.video.views}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    const SizedBox(width: 16),
                    const Icon(Icons.favorite, color: Colors.white54, size: 16),
                    const SizedBox(width: 4),
                    Text('${widget.video.likesCount}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
                if (widget.video.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.video.description,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
