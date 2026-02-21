import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lugmatic_flutter/core/network/api_client.dart';
import 'package:lugmatic_flutter/core/network/token_storage.dart';
import 'package:lugmatic_flutter/data/models/live_stream_model.dart';
import 'package:lugmatic_flutter/data/services/live_stream_service.dart';
import 'package:lugmatic_flutter/data/services/socket_service.dart';
import 'package:lugmatic_flutter/features/live_stream/presentation/widgets/live_video_widget.dart';

/// TikTok-style vertical-swiping live stream page.
///
/// Fetches live streams from the API, connects to LiveKit for video,
/// and uses Socket.io for real-time chat and gifts.
class TikTokLivePage extends StatefulWidget {
  const TikTokLivePage({Key? key}) : super(key: key);

  @override
  State<TikTokLivePage> createState() => _TikTokLivePageState();
}

class _TikTokLivePageState extends State<TikTokLivePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _liveIndicatorController;
  final PageController _pageController = PageController();
  final TextEditingController _commentController = TextEditingController();

  late LiveStreamService _liveStreamService;
  late SocketService _socketService;

  List<LiveStreamModel> _liveStreams = [];
  List<LiveStreamChatMessage> _comments = [];
  Map<String, LiveStreamTokenData> _tokenCache = {};

  int _currentStreamIndex = 0;
  int _viewerCount = 0;
  bool _isFollowing = false;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoading = true;
  String? _error;

  StreamSubscription? _chatSub;
  StreamSubscription? _viewerCountSub;
  StreamSubscription? _streamEndedSub;

  @override
  void initState() {
    super.initState();
    _liveIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
    });
  }

  Future<void> _initServices() async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final tokenStorage = Provider.of<TokenStorage>(context, listen: false);

    _liveStreamService = LiveStreamService(apiClient: apiClient);
    _socketService = SocketService.getInstance(tokenStorage: tokenStorage);

    await _socketService.connect();
    _setupSocketListeners();
    await _fetchStreams();
  }

  void _setupSocketListeners() {
    _chatSub = _socketService.onChatMessage.listen((msg) {
      if (mounted) {
        setState(() {
          _comments.add(msg);
          // Keep last 200 messages
          if (_comments.length > 200) {
            _comments = _comments.sublist(_comments.length - 200);
          }
        });
      }
    });

    _viewerCountSub = _socketService.onViewerCountChanged.listen((count) {
      if (mounted) {
        setState(() => _viewerCount = count);
      }
    });

    _streamEndedSub = _socketService.onStreamEnded.listen((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stream has ended')),
        );
      }
    });
  }

  Future<void> _fetchStreams() async {
    try {
      final streams = await _liveStreamService.getLiveStreams(status: 'live');
      if (mounted) {
        setState(() {
          _liveStreams = streams;
          _isLoading = false;
          if (streams.isNotEmpty) {
            _viewerCount = streams[0].currentViewers;
            _joinCurrentStream();
          }
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

  void _joinCurrentStream() {
    if (_liveStreams.isEmpty) return;
    final stream = _liveStreams[_currentStreamIndex];
    _socketService.joinStream(stream.id);
    _viewerCount = stream.currentViewers;
    _likeCount = stream.totalGiftsReceived;
    _comments.clear();

    // Load initial chat messages from stream data
    for (final msg in stream.chatMessages) {
      _comments.add(msg);
    }

    // Fetch token for current stream
    _fetchToken(stream.id);
  }

  Future<void> _fetchToken(String streamId) async {
    if (_tokenCache.containsKey(streamId)) return;
    try {
      final tokenData = await _liveStreamService.getStreamToken(streamId);
      if (mounted) {
        setState(() {
          _tokenCache[streamId] = tokenData;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch token for stream $streamId: $e');
    }
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _viewerCountSub?.cancel();
    _streamEndedSub?.cancel();
    if (_liveStreams.isNotEmpty) {
      _socketService.leaveStream(_liveStreams[_currentStreamIndex].id);
    }
    _liveIndicatorController.dispose();
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() {
    if (_commentController.text.trim().isEmpty || _liveStreams.isEmpty) return;
    final streamId = _liveStreams[_currentStreamIndex].id;
    _socketService.sendChat(streamId, _commentController.text.trim());
    _commentController.clear();
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    if (_liveStreams.isNotEmpty) {
      _socketService.sendReaction(
        _liveStreams[_currentStreamIndex].id,
        _isLiked ? 'like' : 'unlike',
      );
    }
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null || _liveStreams.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.live_tv, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              Text(
                _error ?? 'No live streams right now',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video/Audio Background via PageView
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              // Leave old stream, join new
              _socketService.leaveStream(_liveStreams[_currentStreamIndex].id);
              setState(() {
                _currentStreamIndex = index;
              });
              _joinCurrentStream();
            },
            itemCount: _liveStreams.length,
            itemBuilder: (context, index) {
              final stream = _liveStreams[index];
              final tokenData = _tokenCache[stream.id];
              if (tokenData != null) {
                return LiveVideoWidget(
                  tokenData: tokenData,
                  isHost: tokenData.isHost,
                );
              }
              // While token is loading, show gradient placeholder
              return _buildPlaceholderBackground(stream);
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

  Widget _buildPlaceholderBackground(LiveStreamModel stream) {
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (stream.host?.image.isNotEmpty == true)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  image: DecorationImage(
                    image: NetworkImage(stream.host!.image),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white24,
                ),
                child: Center(
                  child: Text(
                    stream.host?.name.isNotEmpty == true
                        ? stream.host!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              stream.host?.name ?? 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stream.title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: Colors.white54),
          ],
        ),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(
                              0.8 + (_liveIndicatorController.value * 0.2)),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
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
    if (_liveStreams.isEmpty) return const SizedBox.shrink();
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
                image: currentStream.host?.image.isNotEmpty == true
                    ? DecorationImage(
                        image: NetworkImage(currentStream.host!.image),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.white24,
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
                  : (currentStream.host?.image.isNotEmpty != true
                      ? Center(
                          child: Text(
                            currentStream.host?.name.isNotEmpty == true
                                ? currentStream.host!.name[0]
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null),
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
            onTap: _showCommentInput,
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
              if (_liveStreams.isNotEmpty) {
                _socketService.sendGift(
                  _liveStreams[_currentStreamIndex].id,
                  'love',
                  'Love',
                  10,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gift sent!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
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
    if (_liveStreams.isEmpty) return const SizedBox.shrink();
    final currentStream = _liveStreams[_currentStreamIndex];

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
                  currentStream.host?.name ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (currentStream.host?.verified == true)
                  const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              currentStream.title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Category & Gift buttons
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentStream.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _toggleFollow,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      style: const TextStyle(
                        color: Colors.white,
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
            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: _comments.length,
                reverse: false,
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

  Widget _buildCommentItem(LiveStreamChatMessage comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (comment.isGift) ...[
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ] else if (comment.isSystem) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${comment.username}: ',
                    style: TextStyle(
                      color: comment.isGift
                          ? const Color(0xFFFFD700)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: comment.message,
                    style: TextStyle(
                      color: comment.isSystem
                          ? Colors.white54
                          : Colors.white,
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
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) {
                  _sendComment();
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                _sendComment();
                Navigator.pop(context);
              },
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
