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

class _VideosPageState extends State<VideosPage> with SingleTickerProviderStateMixin {
  late VideoService _videoService;
  List<VideoModel> _allVideos = [];
  bool _isLoading = true;
  String? _error;
  int _selectedFilter = 0;

  static const _filters = ['All', 'Most Views', 'New', 'Shelling'];

  @override
  void initState() {
    super.initState();
    _videoService = context.read<VideoService>();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final videos = await _videoService.getFeedVideos();
      if (mounted) {
        setState(() {
          _allVideos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load videos'; _isLoading = false; });
    }
  }

  List<VideoModel> get _filteredVideos {
    final sorted = List<VideoModel>.from(_allVideos);
    if (_selectedFilter == 1 || _selectedFilter == 3) {
      sorted.sort((a, b) => b.views.compareTo(a.views));
    } else if (_selectedFilter == 2) {
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  }

  List<VideoModel> get _shellingVideos {
    final sorted = List<VideoModel>.from(_allVideos)
      ..sort((a, b) => b.views.compareTo(a.views));
    return sorted.take(8).toList();
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: RefreshIndicator(
        onRefresh: _loadVideos,
        color: const Color(0xFF10B981),
        backgroundColor: const Color(0xFF1F2937),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
              )
            else if (_error != null)
              SliverFillRemaining(child: _buildError())
            else if (_allVideos.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No videos yet', style: TextStyle(color: Colors.white54))),
              )
            else ...[
              // What's Shelling section
              if (_shellingVideos.isNotEmpty) ...[
                _buildSectionHeader(
                  '🔥 What\'s Shelling',
                  subtitle: 'Most viewed right now',
                  accent: const Color(0xFFFF4D4D),
                ),
                SliverToBoxAdapter(child: _buildShellingRow()),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
              // Filter tabs
              SliverToBoxAdapter(child: _buildFilterTabs()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // Grid
              _buildVideoGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF0A0A0F),
      elevation: 0,
      pinned: true,
      expandedHeight: 0,
      title: Row(
        children: [
          const Text(
            'Videos',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4D4D), Color(0xFFFF8C00)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle, Color? accent}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedFilter = 1),
              child: Text('See all',
                  style: TextStyle(color: accent ?? const Color(0xFF10B981), fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShellingRow() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _shellingVideos.length,
        itemBuilder: (context, index) {
          final video = _shellingVideos[index];
          return _ShellingCard(
            video: video,
            rank: index + 1,
            formatCount: _formatCount,
            onTap: () => _openPlayer(video),
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_filters.length, (i) {
            final selected = _selectedFilter == i;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    _filters[i],
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.white,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildVideoGrid() {
    final videos = _filteredVideos;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _VideoGridCard(
            video: videos[index],
            formatCount: _formatCount,
            onTap: () => _openPlayer(videos[index]),
          ),
          childCount: videos.length,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off, color: Colors.white30, size: 56),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadVideos,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _openPlayer(VideoModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
    );
  }
}

// ── Shelling card (horizontal scroll) ────────────────────────────────────────

class _ShellingCard extends StatelessWidget {
  final VideoModel video;
  final int rank;
  final String Function(int) formatCount;
  final VoidCallback onTap;

  const _ShellingCard({
    Key? key,
    required this.video,
    required this.rank,
    required this.formatCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              video.thumbnailUrl.isNotEmpty
                  ? Image.network(video.thumbnailUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1F2937)))
                  : Container(color: const Color(0xFF1F2937)),
              // Dark gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              // Rank badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: rank <= 3
                        ? const LinearGradient(colors: [Color(0xFFFF4D4D), Color(0xFFFF8C00)])
                        : null,
                    color: rank > 3 ? Colors.black54 : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('#$rank',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ),
              // Play icon
              const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40),
              ),
              // Info
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.title,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.play_arrow, color: Colors.white70, size: 12),
                        const SizedBox(width: 3),
                        Text(formatCount(video.views),
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
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

// ── Grid card ─────────────────────────────────────────────────────────────────

class _VideoGridCard extends StatelessWidget {
  final VideoModel video;
  final String Function(int) formatCount;
  final VoidCallback onTap;

  const _VideoGridCard({
    Key? key,
    required this.video,
    required this.formatCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            video.thumbnailUrl.isNotEmpty
                ? Image.network(video.thumbnailUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1F2937)))
                : Container(color: const Color(0xFF1F2937)),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xDD000000)],
                  stops: [0.45, 1.0],
                ),
              ),
            ),
            const Positioned(
              top: 10,
              right: 10,
              child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 26),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(video.artistName,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.white54, size: 13),
                      const SizedBox(width: 3),
                      Text(formatCount(video.views),
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(width: 10),
                      const Icon(Icons.favorite, color: Colors.white54, size: 12),
                      const SizedBox(width: 3),
                      Text(formatCount(video.likesCount),
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Video player screen ────────────────────────────────────────────────────────

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  const VideoPlayerScreen({Key? key, required this.video}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _playerController;
  ChewieController? _chewieController;
  bool _isInitializing = true;
  String? _initError;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _playerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
      );
      await _playerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _playerController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        autoInitialize: true,
        aspectRatio: _playerController!.value.aspectRatio,
        placeholder: widget.video.thumbnailUrl.isNotEmpty
            ? Image.network(widget.video.thumbnailUrl, fit: BoxFit.cover)
            : const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, msg) => Center(
          child: Text(msg, style: const TextStyle(color: Colors.white)),
        ),
      );
      if (mounted) setState(() => _isInitializing = false);
      context.read<VideoService>().incrementViews(widget.video.id);
    } catch (e) {
      if (mounted) setState(() { _isInitializing = false; _initError = e.toString(); });
    }
  }

  @override
  void dispose() {
    _playerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Status bar spacer
          SizedBox(height: MediaQuery.of(context).padding.top),
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(widget.video.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          // Video player
          Container(
            color: Colors.black,
            child: _isInitializing
                ? const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
                  )
                : _initError != null
                    ? AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 8),
                              const Text('Could not load video',
                                  style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      )
                    : AspectRatio(
                        aspectRatio: _playerController!.value.aspectRatio,
                        child: Chewie(controller: _chewieController!),
                      ),
          ),
          // Info panel
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.video.title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white12,
                        child: Icon(Icons.person, color: Colors.white54, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(widget.video.artistName,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                      _ActionButton(
                        icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                        label: _formatCount(widget.video.likesCount + (_isLiked ? 1 : 0)),
                        color: _isLiked ? Colors.redAccent : Colors.white70,
                        onTap: () => setState(() => _isLiked = !_isLiked),
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        color: Colors.white70,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.white38, size: 16),
                      const SizedBox(width: 4),
                      Text(_formatCount(widget.video.views),
                          style: const TextStyle(color: Colors.white38, fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(_timeAgo(widget.video.createdAt),
                          style: const TextStyle(color: Colors.white38, fontSize: 13)),
                    ],
                  ),
                  if (widget.video.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(widget.video.description,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
