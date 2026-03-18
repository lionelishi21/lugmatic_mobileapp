import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lugmatic_flutter/core/network/api_client.dart';
import 'package:lugmatic_flutter/data/models/live_stream_model.dart';
import 'package:lugmatic_flutter/data/services/live_stream_service.dart';
import 'package:lugmatic_flutter/features/live_stream/presentation/pages/tiktok_live_page.dart';

class StreamPage extends StatefulWidget {
  const StreamPage({Key? key}) : super(key: key);

  @override
  State<StreamPage> createState() => _StreamPageState();
}

class _StreamPageState extends State<StreamPage> {
  late LiveStreamService _liveStreamService;
  List<LiveStreamModel> _liveStreams = [];
  List<LiveStreamModel> _upcomingStreams = [];
  List<LiveStreamModel> _pastStreams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    _liveStreamService = LiveStreamService(apiClient: apiClient);
    await _fetchStreams();
  }

  Future<void> _fetchStreams() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allStreams = await _liveStreamService.getLiveStreams();
      if (mounted) {
        setState(() {
          _liveStreams = allStreams.where((s) => s.status == 'live').toList();
          _upcomingStreams = allStreams.where((s) => s.status == 'scheduled').toList();
          _pastStreams = allStreams.where((s) => s.status == 'ended').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load streams';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : RefreshIndicator(
              onRefresh: _fetchStreams,
              color: const Color(0xFF10B981),
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildLiveIndicator(),
                        const SizedBox(height: 24),
                        if (_liveStreams.isNotEmpty) ...[
                          _buildCurrentlyLive(),
                          const SizedBox(height: 32),
                        ],
                        _buildSectionHeader('Live Now'),
                        const SizedBox(height: 16),
                        _buildLiveStreams(),
                        const SizedBox(height: 32),
                        if (_upcomingStreams.isNotEmpty) ...[
                          _buildSectionHeader('Upcoming Streams'),
                          const SizedBox(height: 16),
                          _buildUpcomingStreams(),
                          const SizedBox(height: 32),
                        ],
                        if (_pastStreams.isNotEmpty) ...[
                          _buildSectionHeader('Past Streams'),
                          const SizedBox(height: 16),
                          _buildPastStreams(),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: const Color(0xFF111827),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Live Streams',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => print('Search streams'),
        ),
      ],
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.2),
            Colors.red.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_liveStreams.length} streams live now',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Icon(Icons.live_tv, color: Colors.red, size: 20),
        ],
      ),
    );
  }

  Widget _buildCurrentlyLive() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.2),
            const Color(0xFF10B981).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(_liveStreams[0].coverImage.isNotEmpty 
                      ? _liveStreams[0].coverImage 
                      : 'https://via.placeholder.com/300x300/10B981/FFFFFF?text=Live'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Currently Live',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_liveStreams[0].host?.name ?? _liveStreams[0].title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_liveStreams[0].category} • ${_liveStreams[0].currentViewers} listening',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
            onPressed: () => _openLiveStream(streamId: _liveStreams[0].id),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Join Stream'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLiveStreams() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _liveStreams.length,
        itemBuilder: (context, index) {
          final stream = _liveStreams[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: _buildStreamCard(stream, true),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingStreams() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _upcomingStreams.length,
        itemBuilder: (context, index) {
          final stream = _upcomingStreams[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: _buildStreamCard(stream, false),
          );
        },
      ),
    );
  }

  Widget _buildPastStreams() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(_pastStreams.length, (index) {
          final stream = _pastStreams[index];
          return _buildPastStreamItem(stream);
        }),
      ),
    );
  }

  Widget _buildStreamCard(LiveStreamModel stream, bool isLive) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: isLive ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => isLive ? _openLiveStream(streamId: stream.id) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(stream.coverImage.isNotEmpty 
                            ? stream.coverImage 
                            : 'https://via.placeholder.com/300x300/10B981/FFFFFF?text=Stream'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (isLive)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  stream.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  stream.host?.name ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  stream.category,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPastStreamItem(LiveStreamModel stream) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(stream.coverImage.isNotEmpty 
                  ? stream.coverImage 
                  : 'https://via.placeholder.com/300x300/6B7280/FFFFFF?text=Past'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stream.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stream.host?.name ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stream.category} • ${_formatDuration(Duration(minutes: stream.duration))}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openLiveStream(streamId: stream.id),
            icon: const Icon(Icons.play_circle_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _openLiveStream({String? streamId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TikTokLivePage(initialStreamId: streamId),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
