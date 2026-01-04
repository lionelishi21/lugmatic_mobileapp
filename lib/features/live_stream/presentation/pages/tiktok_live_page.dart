import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/artist_model.dart';
import 'package:lugmatic_flutter/features/gift/presentation/pages/gift_send_page.dart';

class TikTokLivePage extends StatefulWidget {
  final ArtistModel artist;
  
  const TikTokLivePage({Key? key, required this.artist}) : super(key: key);

  @override
  State<TikTokLivePage> createState() => _TikTokLivePageState();
}

class _TikTokLivePageState extends State<TikTokLivePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _liveIndicatorController;
  final PageController _pageController = PageController();
  final TextEditingController _commentController = TextEditingController();
  final List<LiveStreamComment> _comments = [];
  int _currentStreamIndex = 0;
  int _viewerCount = 1247;
  bool _isFollowing = false;
  bool _isLiked = false;
  int _likeCount = 892;

  final List<LiveStreamData> _liveStreams = [
    LiveStreamData(
      artist: ArtistModel(
        id: '1',
        name: 'Luna Nova',
        imageUrl: 'https://via.placeholder.com/300x300/10B981/FFFFFF?text=Luna',
        bio: 'Electronic music producer creating cosmic soundscapes',
        followers: 125000,
        genres: ['Electronic', 'Ambient', 'Synthwave'],
        isVerified: true,
        location: 'Los Angeles, CA',
        totalSongs: 45,
        totalAlbums: 8,
        rating: 4.8,
      ),
      songTitle: 'Midnight Dreams',
      viewerCount: 1247,
      isLive: true,
    ),
    LiveStreamData(
      artist: ArtistModel(
        id: '2',
        name: 'Marine Sounds',
        imageUrl: 'https://via.placeholder.com/300x300/8B5CF6/FFFFFF?text=Marine',
        bio: 'Nature-inspired ambient music for relaxation',
        followers: 89000,
        genres: ['Ambient', 'Nature', 'Meditation'],
        isVerified: true,
        location: 'Portland, OR',
        totalSongs: 32,
        totalAlbums: 6,
        rating: 4.9,
      ),
      songTitle: 'Ocean Waves',
      viewerCount: 892,
      isLive: true,
    ),
    LiveStreamData(
      artist: ArtistModel(
        id: '3',
        name: 'Urban Beats',
        imageUrl: 'https://via.placeholder.com/300x300/EF4444/FFFFFF?text=Urban',
        bio: 'Hip-hop artist bringing fresh urban vibes',
        followers: 156000,
        genres: ['Hip-Hop', 'Rap', 'Urban'],
        isVerified: true,
        location: 'New York, NY',
        totalSongs: 67,
        totalAlbums: 12,
        rating: 4.7,
      ),
      songTitle: 'City Lights',
      viewerCount: 2156,
      isLive: true,
    ),
    LiveStreamData(
      artist: ArtistModel(
        id: '4',
        name: 'Chris Brown',
        imageUrl: 'assets/images/onboarding_guy.png',
        bio: 'Multi-platinum R&B and hip-hop artist, dancer, and actor',
        followers: 45000000,
        genres: ['R&B', 'Hip-Hop', 'Pop'],
        isVerified: true,
        location: 'Tappahannock, VA',
        totalSongs: 200,
        totalAlbums: 15,
        rating: 4.9,
      ),
      songTitle: 'Under The Influence',
      viewerCount: 12500,
      isLive: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _liveIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _addDummyComments();
  }

  void _addDummyComments() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _comments.add(LiveStreamComment(
            username: 'MusicLover23',
            message: 'This is amazing! 🔥',
            isArtist: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _comments.add(LiveStreamComment(
            username: 'SoundWave99',
            message: 'Love this song!',
            isArtist: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _comments.add(LiveStreamComment(
            username: widget.artist.name,
            message: 'Thanks everyone! ❤️',
            isArtist: true,
            timestamp: DateTime.now(),
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _liveIndicatorController.dispose();
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _comments.add(LiveStreamComment(
        username: 'You',
        message: _commentController.text,
        isArtist: false,
        timestamp: DateTime.now(),
      ));
      _commentController.clear();
    });
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Background
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() {
                _currentStreamIndex = index;
              });
            },
            itemCount: _liveStreams.length,
            itemBuilder: (context, index) {
              final stream = _liveStreams[index];
              return _buildVideoBackground(stream);
            },
          ),
          
          // Top UI Overlay
          _buildTopOverlay(),
          
          // Right Side UI (Profile, Actions)
          _buildRightSideUI(),
          
          // Bottom UI (Comments)
          _buildBottomUI(),
        ],
      ),
    );
  }

  Widget _buildVideoBackground(LiveStreamData stream) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.8),
            Colors.blue.withOpacity(0.8),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated background elements
          Positioned(
            top: 100,
            left: 50,
            child: AnimatedBuilder(
              animation: _liveIndicatorController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (_liveIndicatorController.value * 0.4),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 200,
            right: 80,
            child: AnimatedBuilder(
              animation: _liveIndicatorController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.6 + (_liveIndicatorController.value * 0.3),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    image: DecorationImage(
                      image: NetworkImage(stream.artist.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  stream.artist.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Now Playing: ${stream.songTitle}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              
              // Live indicator and viewer count
              Row(
                children: [
                  // Live indicator
                  AnimatedBuilder(
                    animation: _liveIndicatorController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8 + (_liveIndicatorController.value * 0.2)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Viewer count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.remove_red_eye,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_viewerCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightSideUI() {
    final currentStream = _liveStreams[_currentStreamIndex];
    
    return Positioned(
      right: 16,
      bottom: 200,
      child: Column(
        children: [
          // Profile picture
          GestureDetector(
            onTap: _toggleFollow,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isFollowing ? Colors.red : Colors.white,
                  width: 2,
                ),
                image: DecorationImage(
                  image: NetworkImage(currentStream.artist.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: _isFollowing
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.8),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          
          // Like button
          GestureDetector(
            onTap: _toggleLike,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_likeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Comment button
          GestureDetector(
            onTap: () {
              // Show comment input
              _showCommentInput();
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_comments.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Share button
          GestureDetector(
            onTap: () {
              // Share functionality
              print('Share live stream');
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Gift button
          GestureDetector(
            onTap: () {
              // Navigate to gift page with selected artist
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GiftSendPage(
                    selectedArtist: currentStream.artist,
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: Color(0xFFFFD700),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gift',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomUI() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artist info
            Row(
              children: [
                Text(
                  _liveStreams[_currentStreamIndex].artist.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (_liveStreams[_currentStreamIndex].artist.isVerified)
                  const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Now Playing: ${_liveStreams[_currentStreamIndex].songTitle}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            
            // Gift button in bottom UI
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate to gift page with selected artist
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GiftSendPage(
                          selectedArtist: _liveStreams[_currentStreamIndex].artist,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.card_giftcard,
                          color: Colors.black,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Send Gift',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Follow button
                GestureDetector(
                  onTap: _toggleFollow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isFollowing ? Colors.red : Colors.transparent,
                      border: Border.all(
                        color: _isFollowing ? Colors.red : Colors.white,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: _isFollowing ? Colors.white : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Comments section
            Container(
              height: 120,
              child: ListView.builder(
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return _buildCommentItem(comment);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(LiveStreamComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (comment.isArtist) ...[
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${comment.username}: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: comment.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentInput() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendComment,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveStreamData {
  final ArtistModel artist;
  final String songTitle;
  final int viewerCount;
  final bool isLive;

  LiveStreamData({
    required this.artist,
    required this.songTitle,
    required this.viewerCount,
    required this.isLive,
  });
}

class LiveStreamComment {
  final String username;
  final String message;
  final bool isArtist;
  final DateTime timestamp;

  LiveStreamComment({
    required this.username,
    required this.message,
    required this.isArtist,
    required this.timestamp,
  });
}
