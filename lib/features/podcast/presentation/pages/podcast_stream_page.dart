import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/podcast_model.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/ui/widgets/music_player_widget.dart';

class PodcastStreamPage extends StatefulWidget {
  const PodcastStreamPage({Key? key}) : super(key: key);

  @override
  State<PodcastStreamPage> createState() => _PodcastStreamPageState();
}

class _PodcastStreamPageState extends State<PodcastStreamPage> {
  final List<PodcastModel> _livePodcasts = [
    PodcastModel(
      id: '1',
      title: 'Tech Talk Live',
      description: 'Live discussion about the latest in technology',
      host: 'Sarah Johnson',
      imageUrl: 'https://via.placeholder.com/300x300/10B981/FFFFFF?text=Tech+Live',
      audioUrl: 'https://example.com/tech-live.mp3',
      duration: const Duration(minutes: 90),
      category: 'Technology',
      publishDate: DateTime.now(),
      episodeNumber: 42,
      totalEpisodes: 100,
      seriesId: 'tech_talk',
      seriesTitle: 'Tech Talk Live',
      tags: ['technology', 'live', 'discussion'],
    ),
    PodcastModel(
      id: '2',
      title: 'Mindfulness Monday',
      description: 'Live meditation and wellness session',
      host: 'Dr. Emily Chen',
      imageUrl: 'https://via.placeholder.com/300x300/8B5CF6/FFFFFF?text=Mind+Live',
      audioUrl: 'https://example.com/mindfulness-live.mp3',
      duration: const Duration(minutes: 60),
      category: 'Health & Wellness',
      publishDate: DateTime.now(),
      episodeNumber: 28,
      totalEpisodes: 50,
      seriesId: 'mindfulness_monday',
      seriesTitle: 'Mindfulness Monday',
      tags: ['wellness', 'meditation', 'live'],
    ),
    PodcastModel(
      id: '3',
      title: 'Business Insights Live',
      description: 'Real-time business news and analysis',
      host: 'Michael Rodriguez',
      imageUrl: 'https://via.placeholder.com/300x300/F59E0B/FFFFFF?text=Biz+Live',
      audioUrl: 'https://example.com/business-live.mp3',
      duration: const Duration(minutes: 75),
      category: 'Business',
      publishDate: DateTime.now(),
      episodeNumber: 156,
      totalEpisodes: 200,
      seriesId: 'business_insights',
      seriesTitle: 'Business Insights Live',
      tags: ['business', 'finance', 'live'],
    ),
  ];

  final List<PodcastModel> _upcomingPodcasts = [
    PodcastModel(
      id: '4',
      title: 'Science Weekly',
      description: 'Upcoming episode about space exploration',
      host: 'Dr. Alex Thompson',
      imageUrl: 'https://via.placeholder.com/300x300/06B6D4/FFFFFF?text=Science',
      audioUrl: '',
      duration: const Duration(minutes: 45),
      category: 'Science',
      publishDate: DateTime.now().add(const Duration(hours: 2)),
      episodeNumber: 89,
      totalEpisodes: 120,
      seriesId: 'science_weekly',
      seriesTitle: 'Science Weekly',
      tags: ['science', 'space', 'exploration'],
    ),
    PodcastModel(
      id: '5',
      title: 'Art & Culture',
      description: 'Discussion about contemporary art movements',
      host: 'Lisa Park',
      imageUrl: 'https://via.placeholder.com/300x300/EC4899/FFFFFF?text=Art',
      audioUrl: '',
      duration: const Duration(minutes: 50),
      category: 'Arts',
      publishDate: DateTime.now().add(const Duration(hours: 4)),
      episodeNumber: 67,
      totalEpisodes: 80,
      seriesId: 'art_culture',
      seriesTitle: 'Art & Culture',
      tags: ['art', 'culture', 'contemporary'],
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
                _buildLivePodcasts(),
                const SizedBox(height: 32),
                _buildSectionHeader('Upcoming Shows'),
                const SizedBox(height: 16),
                _buildUpcomingPodcasts(),
                const SizedBox(height: 32),
                _buildSectionHeader('Popular Series'),
                const SizedBox(height: 16),
                _buildPopularSeries(),
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
        'Live Podcasts',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => print('Search podcasts'),
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
            Colors.green.withOpacity(0.2),
            Colors.green.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '3 podcasts live now',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Icon(Icons.mic, color: Colors.green, size: 20),
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
            const Color(0xFF8B5CF6).withOpacity(0.2),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
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
                    image: NetworkImage('https://via.placeholder.com/300x300/8B5CF6/FFFFFF?text=Live'),
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
                        color: Color(0xFF8B5CF6),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tech Talk Live - Episode 42',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Technology • 850 listening',
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
                  color: Colors.green,
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
              onPressed: () => _openPodcastPlayer(_livePodcasts[0]),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Join Live Podcast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
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

  Widget _buildLivePodcasts() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _livePodcasts.length,
        itemBuilder: (context, index) {
          final podcast = _livePodcasts[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            child: _buildPodcastCard(podcast, true),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingPodcasts() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _upcomingPodcasts.length,
        itemBuilder: (context, index) {
          final podcast = _upcomingPodcasts[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            child: _buildPodcastCard(podcast, false),
          );
        },
      ),
    );
  }

  Widget _buildPopularSeries() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSeriesItem('Tech Talk Live', 'Technology', 100, 'https://via.placeholder.com/300x300/10B981/FFFFFF?text=Tech'),
          const SizedBox(height: 12),
          _buildSeriesItem('Mindfulness Monday', 'Health & Wellness', 50, 'https://via.placeholder.com/300x300/8B5CF6/FFFFFF?text=Mind'),
          const SizedBox(height: 12),
          _buildSeriesItem('Business Insights', 'Business', 200, 'https://via.placeholder.com/300x300/F59E0B/FFFFFF?text=Biz'),
        ],
      ),
    );
  }

  Widget _buildPodcastCard(PodcastModel podcast, bool isLive) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: isLive ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => isLive ? _openPodcastPlayer(podcast) : null,
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
                          image: NetworkImage(podcast.imageUrl),
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
                            color: Colors.green,
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
                  podcast.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  podcast.host,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  podcast.category,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Colors.white.withOpacity(0.5),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatNumber(podcast.playCount)} listening',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesItem(String title, String category, int episodes, String imageUrl) {
    return Container(
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
                image: NetworkImage(imageUrl),
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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$episodes episodes',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => print('Subscribe to $title'),
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _openPodcastPlayer(PodcastModel podcast) {
    // Convert podcast to music model for playback
    final musicModel = MusicModel(
      id: podcast.id,
      title: podcast.title,
      artist: podcast.host,
      album: podcast.seriesTitle,
      imageUrl: podcast.imageUrl,
      audioUrl: podcast.audioUrl,
      duration: podcast.duration,
      genre: podcast.category,
      releaseDate: podcast.publishDate,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerWidget(music: musicModel),
        fullscreenDialog: true,
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
