import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/music_model.dart';
import '../../../../data/models/video_model.dart';
import '../../../../data/providers/audio_provider.dart';
import '../../../../data/services/home_service.dart';
import '../../../../data/services/video_service.dart';
import '../../../../core/network/api_client.dart';

// ── feed item union type ──────────────────────────────────────────────────
enum _FeedType { song, video }

class _FeedItem {
  final _FeedType type;
  final MusicModel? song;
  final VideoModel? video;

  const _FeedItem.song(this.song)
      : type = _FeedType.song,
        video = null;
  const _FeedItem.video(this.video)
      : type = _FeedType.video,
        song = null;

  String get id => type == _FeedType.song ? song!.id : video!.id;
  String get title => type == _FeedType.song ? song!.title : video!.title;
  String get artistName => type == _FeedType.song ? song!.artist : video!.artistName;
  String get imageUrl =>
      type == _FeedType.song ? song!.imageUrl : video!.thumbnailUrl;
  String get genre => type == _FeedType.song ? (song!.genre) : '';
}

// ── genre chips ────────────────────────────────────────────────────────────
const _kGenres = [
  'All', 'Afrobeats', 'Hip-Hop', 'R&B', 'Pop', 'Dancehall', 'Gospel', 'Reggae',
];

// ── main page ─────────────────────────────────────────────────────────────
class ForYouFeedPage extends StatefulWidget {
  const ForYouFeedPage({super.key});

  @override
  State<ForYouFeedPage> createState() => _ForYouFeedPageState();
}

class _ForYouFeedPageState extends State<ForYouFeedPage>
    with AutomaticKeepAliveClientMixin {
  late HomeService _homeService;
  late VideoService _videoService;

  List<_FeedItem> _allItems = [];
  List<_FeedItem> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _activeGenre = 'All';

  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final client = context.read<ApiClient>();
    _homeService = HomeService(apiClient: client);
    _videoService = VideoService(apiClient: client);
    _loadFeed();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _homeService.getTrendingSongs(),
        _homeService.getNewReleases(),
        _videoService.getFeedVideos(),
      ]);
      if (!mounted) return;
      final trending = results[0] as List<MusicModel>;
      final newReleases = results[1] as List<MusicModel>;
      final videos = results[2] as List<VideoModel>;

      // Deduplicate songs
      final songMap = <String, MusicModel>{};
      for (final s in [...trending, ...newReleases]) {
        songMap[s.id] = s;
      }

      // Build interleaved feed: song, song, video, song, song, video...
      final songs = songMap.values.toList()..shuffle(math.Random(42));
      final vids = videos.toList();
      final feed = <_FeedItem>[];
      int si = 0, vi = 0;
      while (si < songs.length || vi < vids.length) {
        if (si < songs.length) feed.add(_FeedItem.song(songs[si++]));
        if (si < songs.length) feed.add(_FeedItem.song(songs[si++]));
        if (vi < vids.length) feed.add(_FeedItem.video(vids[vi++]));
      }

      setState(() {
        _allItems = feed;
        _filtered = feed;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _setGenre(String genre) {
    setState(() {
      _activeGenre = genre;
      _filtered = genre == 'All'
          ? _allItems
          : _allItems.where((item) {
              if (item.type == _FeedType.video) return false;
              return item.genre.toLowerCase().contains(genre.toLowerCase());
            }).toList();
      _currentPage = 0;
    });
    _pageCtrl.jumpToPage(0);
  }

  void _playItem(_FeedItem item) {
    if (item.type == _FeedType.song) {
      final queue = _filtered
          .where((i) => i.type == _FeedType.song)
          .map((i) => i.song!)
          .toList();
      context.read<AudioProvider>().playMusic(item.song!, queue: queue);
    } else {
      Navigator.pushNamed(context, '/video-player', arguments: item.video);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GenreTab(
              label: 'Following',
              active: false,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            const Text('·', style: TextStyle(color: Colors.white38)),
            const SizedBox(width: 8),
            _GenreTab(
              label: 'For You',
              active: true,
              onTap: () {},
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _filtered.isEmpty
                  ? _buildEmpty()
                  : Stack(
                      children: [
                        // Full-screen vertical PageView
                        PageView.builder(
                          controller: _pageCtrl,
                          scrollDirection: Axis.vertical,
                          onPageChanged: (i) => setState(() => _currentPage = i),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) => _FeedCard(
                            item: _filtered[i],
                            isActive: i == _currentPage,
                            onPlay: () => _playItem(_filtered[i]),
                          ),
                        ),
                        // Genre chips overlay at bottom
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: _GenreChips(
                            genres: _kGenres,
                            active: _activeGenre,
                            onSelect: _setGenre,
                          ),
                        ),
                        // Progress dots on right
                        Positioned(
                          right: 12,
                          top: 0,
                          bottom: 80,
                          child: Center(
                            child: _ProgressDots(
                              count: math.min(_filtered.length, 10),
                              current: math.min(_currentPage, 9),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFeed,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          const Text('No content for this genre yet', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _setGenre('All'),
            child: const Text('Show All', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── genre tab (Following / For You toggle) ────────────────────────────────
class _GenreTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _GenreTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white38,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          if (active)
            Container(
              height: 3,
              width: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

// ── genre chips row ────────────────────────────────────────────────────────
class _GenreChips extends StatelessWidget {
  final List<String> genres;
  final String active;
  final void Function(String) onSelect;

  const _GenreChips({required this.genres, required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final g = genres[i];
          final sel = g == active;
          return GestureDetector(
            onTap: () => onSelect(g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: sel ? AppColors.primary : Colors.white24,
                ),
              ),
              child: Text(
                g,
                style: TextStyle(
                  color: sel ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── progress dots ──────────────────────────────────────────────────────────
class _ProgressDots extends StatelessWidget {
  final int count, current;

  const _ProgressDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 3,
          height: active ? 20 : 4,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white30,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

// ── feed card ─────────────────────────────────────────────────────────────
class _FeedCard extends StatefulWidget {
  final _FeedItem item;
  final bool isActive;
  final VoidCallback onPlay;

  const _FeedCard({required this.item, required this.isActive, required this.onPlay});

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> with SingleTickerProviderStateMixin {
  late AnimationController _vinylCtrl;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _vinylCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void didUpdateWidget(_FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_vinylCtrl.isAnimating) {
      _vinylCtrl.repeat();
    } else if (!widget.isActive) {
      _vinylCtrl.stop();
    }
  }

  @override
  void dispose() {
    _vinylCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final imgUrl = ApiConfig.resolveUrl(item.imageUrl);
    final isSong = item.type == _FeedType.song;

    return GestureDetector(
      onDoubleTap: () {
        setState(() => _liked = true);
        HapticFeedback.lightImpact();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background art
          _BackgroundArt(imageUrl: imgUrl),

          // Type badge (top left)
          Positioned(
            top: 100,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSong ? AppColors.primary.withOpacity(0.85) : Colors.deepOrangeAccent.withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isSong ? Icons.music_note : Icons.videocam, size: 11, color: Colors.black),
                  const SizedBox(width: 4),
                  Text(
                    isSong ? 'SONG' : 'VIDEO',
                    style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Center vinyl / play button
          Center(
            child: isSong
                ? _VinylDisc(controller: _vinylCtrl, imageUrl: imgUrl, onTap: widget.onPlay)
                : _VideoThumbnailPlay(imageUrl: imgUrl, onTap: widget.onPlay),
          ),

          // Bottom info + actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomOverlay(
              item: item,
              liked: _liked,
              onLike: () {
                setState(() => _liked = !_liked);
                HapticFeedback.selectionClick();
              },
              onPlay: widget.onPlay,
              onShare: () {},
            ),
          ),
        ],
      ),
    );
  }
}

// ── blurred background art ────────────────────────────────────────────────
class _BackgroundArt extends StatelessWidget {
  final String imageUrl;
  const _BackgroundArt({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        imageUrl.isNotEmpty
            ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black))
            : Container(color: const Color(0xFF0A0A0F)),
        // Dark gradient overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC000000),
                Color(0x33000000),
                Color(0x33000000),
                Color(0xDD000000),
              ],
              stops: [0.0, 0.25, 0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

// ── vinyl disc widget ──────────────────────────────────────────────────────
class _VinylDisc extends StatelessWidget {
  final AnimationController controller;
  final String imageUrl;
  final VoidCallback onTap;

  const _VinylDisc({required this.controller, required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => Transform.rotate(
          angle: controller.value * 2 * math.pi,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vinyl outer ring
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(color: Colors.white10, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              // Album art circle
              ClipOval(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey[900], child: const Icon(Icons.music_note, color: Colors.white38, size: 48)),
                ),
              ),
              // Center hole
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── video thumbnail play button ────────────────────────────────────────────
class _VideoThumbnailPlay extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;

  const _VideoThumbnailPlay({required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black54,
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
      ),
    );
  }
}

// ── bottom overlay with track info + actions ───────────────────────────────
class _BottomOverlay extends StatelessWidget {
  final _FeedItem item;
  final bool liked;
  final VoidCallback onLike, onPlay, onShare;

  const _BottomOverlay({
    required this.item,
    required this.liked,
    required this.onLike,
    required this.onPlay,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isSong = item.type == _FeedType.song;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 72, 90),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left: track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSong && item.song!.genre.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Text(
                      item.song!.genre,
                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                Text(
                  item.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      item.artistName,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Waveform decoration
                Row(
                  children: List.generate(24, (i) {
                    final h = 4.0 + math.sin(i * 0.8) * 8 + math.cos(i * 1.3) * 4;
                    return Container(
                      width: 3,
                      height: h.abs(),
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right: action buttons (TikTok-style column)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: liked ? Icons.favorite : Icons.favorite_border,
                color: liked ? Colors.redAccent : Colors.white,
                label: '',
                onTap: onLike,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: isSong ? Icons.play_circle_outline : Icons.play_arrow_rounded,
                color: AppColors.primary,
                label: 'Play',
                onTap: onPlay,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.share_outlined,
                color: Colors.white,
                label: 'Share',
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black38,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}
