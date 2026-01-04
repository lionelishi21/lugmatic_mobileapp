import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/ui/widgets/music_player_widget.dart';

class StreamPage extends StatefulWidget {
  const StreamPage({Key? key}) : super(key: key);

  @override
  State<StreamPage> createState() => _StreamPageState();
}

class _StreamPageState extends State<StreamPage> {
  final List<MusicModel> _streamingMusic = [
    MusicModel(
      id: '1',
      title: 'Live Stream Session 1',
      artist: 'DJ Luna',
      album: 'Live Mix',
      imageUrl: 'https://via.placeholder.com/300x300/10B981/FFFFFF?text=Live+1',
      audioUrl: 'https://example.com/stream1.mp3',
      duration: const Duration(minutes: 45),
      genre: 'Electronic',
      releaseDate: DateTime.now(),
    ),
    MusicModel(
      id: '2',
      title: 'Midnight Vibes Stream',
      artist: 'Chill Wave',
      album: 'Live Performance',
      imageUrl: 'https://via.placeholder.com/300x300/8B5CF6/FFFFFF?text=Live+2',
      audioUrl: 'https://example.com/stream2.mp3',
      duration: const Duration(minutes: 60),
      genre: 'Ambient',
      releaseDate: DateTime.now(),
    ),
    MusicModel(
      id: '3',
      title: 'Rock Night Live',
      artist: 'Thunder Band',
      album: 'Live Concert',
      imageUrl: 'https://via.placeholder.com/300x300/EF4444/FFFFFF?text=Live+3',
      audioUrl: 'https://example.com/stream3.mp3',
      duration: const Duration(minutes: 90),
      genre: 'Rock',
      releaseDate: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildLiveIndicator(),
                const SizedBox(height: 24),
                _buildCurrentlyLive(),
                const SizedBox(height: 32),
                _buildSectionHeader('Live Now'),
                const SizedBox(height: 16),
                _buildLiveStreams(),
                const SizedBox(height: 32),
                _buildSectionHeader('Upcoming Streams'),
                const SizedBox(height: 16),
                _buildUpcomingStreams(),
                const SizedBox(height: 32),
                _buildSectionHeader('Past Streams'),
                const SizedBox(height: 16),
                _buildPastStreams(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
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
          const Text(
            '3 streams live now',
            style: TextStyle(
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
                  image: const DecorationImage(
                    image: NetworkImage('https://via.placeholder.com/300x300/10B981/FFFFFF?text=Live'),
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
                    const Text(
                      'DJ Luna - Live Mix Session',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Electronic • 1.2K listening',
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
              onPressed: () => _openMusicPlayer(_streamingMusic[0]),
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
        itemCount: _streamingMusic.length,
        itemBuilder: (context, index) {
          final stream = _streamingMusic[index];
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
        itemCount: 2,
        itemBuilder: (context, index) {
          final stream = MusicModel(
            id: 'upcoming_$index',
            title: 'Upcoming Stream ${index + 1}',
            artist: 'Artist ${index + 1}',
            album: 'Scheduled Performance',
            imageUrl: 'https://via.placeholder.com/300x300/8B5CF6/FFFFFF?text=Soon',
            audioUrl: '',
            duration: const Duration(minutes: 60),
            genre: 'Various',
            releaseDate: DateTime.now().add(Duration(hours: index + 2)),
          );
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
        children: List.generate(3, (index) {
          final stream = MusicModel(
            id: 'past_$index',
            title: 'Past Stream ${index + 1}',
            artist: 'Artist ${index + 1}',
            album: 'Completed Performance',
            imageUrl: 'https://via.placeholder.com/300x300/6B7280/FFFFFF?text=Past',
            audioUrl: '',
            duration: const Duration(minutes: 60),
            genre: 'Various',
            releaseDate: DateTime.now().subtract(Duration(days: index + 1)),
          );
          return _buildPastStreamItem(stream);
        }),
      ),
    );
  }

  Widget _buildStreamCard(MusicModel stream, bool isLive) {
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
          onTap: () => isLive ? _openMusicPlayer(stream) : null,
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
                          image: NetworkImage(stream.imageUrl),
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
                  stream.artist,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  stream.genre,
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

  Widget _buildPastStreamItem(MusicModel stream) {
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
                image: NetworkImage(stream.imageUrl),
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
                  stream.artist,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stream.genre} • ${_formatDuration(stream.duration)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openMusicPlayer(stream),
            icon: const Icon(Icons.play_circle_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _openMusicPlayer(MusicModel music) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerWidget(music: music),
        fullscreenDialog: true,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
