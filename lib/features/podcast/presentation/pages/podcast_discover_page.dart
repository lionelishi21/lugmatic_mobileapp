import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/podcast_model.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/ui/widgets/music_player_widget.dart';

class PodcastDiscoverPage extends StatefulWidget {
  const PodcastDiscoverPage({Key? key}) : super(key: key);

  @override
  State<PodcastDiscoverPage> createState() => _PodcastDiscoverPageState();
}

class _PodcastDiscoverPageState extends State<PodcastDiscoverPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<PodcastModel> _trendingPodcasts = [
    PodcastModel(
      id: '1',
      title: 'The Future of AI',
      description: 'Exploring artificial intelligence and its impact on society',
      host: 'Dr. Sarah Chen',
      imageUrl: 'https://via.placeholder.com/300x300/10B981/FFFFFF?text=AI+Pod',
      audioUrl: 'https://example.com/ai-podcast.mp3',
      duration: const Duration(minutes: 45),
      category: 'Technology',
      publishDate: DateTime.now().subtract(const Duration(days: 1)),
      episodeNumber: 23,
      totalEpisodes: 50,
      seriesId: 'future_ai',
      seriesTitle: 'Tech Insights',
      tags: ['AI', 'technology', 'future'],
    ),
    PodcastModel(
      id: '2',
      title: 'Mindfulness for Beginners',
      description: 'A gentle introduction to meditation and mindfulness practices',
      host: 'Emily Rodriguez',
      imageUrl: 'https://via.placeholder.com/300x300/8B5CF6/FFFFFF?text=Mind+Pod',
      audioUrl: 'https://example.com/mindfulness-podcast.mp3',
      duration: const Duration(minutes: 30),
      category: 'Health & Wellness',
      publishDate: DateTime.now().subtract(const Duration(days: 2)),
      episodeNumber: 15,
      totalEpisodes: 30,
      seriesId: 'mindfulness_beginners',
      seriesTitle: 'Wellness Journey',
      tags: ['mindfulness', 'meditation', 'wellness'],
    ),
    PodcastModel(
      id: '3',
      title: 'Business Success Stories',
      description: 'Inspiring stories from successful entrepreneurs',
      host: 'Michael Johnson',
      imageUrl: 'https://via.placeholder.com/300x300/F59E0B/FFFFFF?text=Biz+Pod',
      audioUrl: 'https://example.com/business-podcast.mp3',
      duration: const Duration(minutes: 60),
      category: 'Business',
      publishDate: DateTime.now().subtract(const Duration(days: 3)),
      episodeNumber: 89,
      totalEpisodes: 120,
      seriesId: 'business_success',
      seriesTitle: 'Entrepreneur Stories',
      tags: ['business', 'success', 'entrepreneurship'],
    ),
  ];

  final List<PodcastModel> _newEpisodes = [
    PodcastModel(
      id: '4',
      title: 'Climate Change Solutions',
      description: 'Innovative approaches to addressing climate change',
      host: 'Dr. Alex Green',
      imageUrl: 'https://via.placeholder.com/300x300/06B6D4/FFFFFF?text=Climate',
      audioUrl: 'https://example.com/climate-podcast.mp3',
      duration: const Duration(minutes: 50),
      category: 'Science',
      publishDate: DateTime.now().subtract(const Duration(hours: 6)),
      episodeNumber: 42,
      totalEpisodes: 75,
      seriesId: 'climate_solutions',
      seriesTitle: 'Environmental Science',
      tags: ['climate', 'environment', 'science'],
    ),
    PodcastModel(
      id: '5',
      title: 'Art History Deep Dive',
      description: 'Exploring the Renaissance period in art history',
      host: 'Lisa Martinez',
      imageUrl: 'https://via.placeholder.com/300x300/EC4899/FFFFFF?text=Art+Pod',
      audioUrl: 'https://example.com/art-podcast.mp3',
      duration: const Duration(minutes: 40),
      category: 'Arts',
      publishDate: DateTime.now().subtract(const Duration(hours: 12)),
      episodeNumber: 18,
      totalEpisodes: 25,
      seriesId: 'art_history',
      seriesTitle: 'Art Through Time',
      tags: ['art', 'history', 'renaissance'],
    ),
  ];

  final List<String> _categories = [
    'Technology', 'Health & Wellness', 'Business', 'Science', 'Arts',
    'Education', 'Entertainment', 'News', 'Sports', 'True Crime', 'Comedy', 'Fiction'
  ];

  final List<Map<String, dynamic>> _featuredSeries = [
    {
      'title': 'Tech Insights',
      'host': 'Dr. Sarah Chen',
      'episodes': 50,
      'category': 'Technology',
      'imageUrl': 'https://via.placeholder.com/300x300/10B981/FFFFFF?text=Tech',
      'description': 'Deep dives into emerging technologies',
    },
    {
      'title': 'Wellness Journey',
      'host': 'Emily Rodriguez',
      'episodes': 30,
      'category': 'Health & Wellness',
      'imageUrl': 'https://via.placeholder.com/300x300/8B5CF6/FFFFFF?text=Well',
      'description': 'Your guide to mental and physical wellness',
    },
    {
      'title': 'Entrepreneur Stories',
      'host': 'Michael Johnson',
      'episodes': 120,
      'category': 'Business',
      'imageUrl': 'https://via.placeholder.com/300x300/F59E0B/FFFFFF?text=Ent',
      'description': 'Success stories from business leaders',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                _buildSearchBar(),
                const SizedBox(height: 24),
                _buildCategoriesGrid(),
                const SizedBox(height: 32),
                _buildSectionHeader('Trending Podcasts', 'See All'),
                const SizedBox(height: 16),
                _buildTrendingPodcasts(),
                const SizedBox(height: 32),
                _buildSectionHeader('New Episodes', 'View All'),
                const SizedBox(height: 16),
                _buildNewEpisodes(),
                const SizedBox(height: 32),
                _buildSectionHeader('Featured Series', 'Browse'),
                const SizedBox(height: 16),
                _buildFeaturedSeries(),
                const SizedBox(height: 32),
                _buildSectionHeader('Recommended for You', ''),
                const SizedBox(height: 16),
                _buildRecommendedPodcasts(),
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
        'Discover Podcasts',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onPressed: () => _showFilterDialog(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search podcasts, hosts, topics...',
          hintStyle: TextStyle(color: Colors.white60),
          prefixIcon: Icon(Icons.search, color: Colors.white60),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          // Handle search query changes
        },
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse by Category',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) => _buildCategoryChip(category)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (action.isNotEmpty)
            TextButton(
              onPressed: () => print('$action tapped'),
              child: Text(
                action,
                style: const TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendingPodcasts() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _trendingPodcasts.length,
        itemBuilder: (context, index) {
          final podcast = _trendingPodcasts[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            child: _buildPodcastCard(podcast),
          );
        },
      ),
    );
  }

  Widget _buildNewEpisodes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _newEpisodes.map((podcast) => _buildPodcastListItem(podcast)).toList(),
      ),
    );
  }

  Widget _buildFeaturedSeries() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _featuredSeries.length,
        itemBuilder: (context, index) {
          final series = _featuredSeries[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: _buildSeriesCard(series),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedPodcasts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _trendingPodcasts.take(2).map((podcast) => _buildPodcastListItem(podcast)).toList(),
      ),
    );
  }

  Widget _buildPodcastCard(PodcastModel podcast) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPodcastPlayer(podcast),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(podcast.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
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
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Colors.green.withOpacity(0.7),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      podcast.category,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Episode ${podcast.episodeNumber}',
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

  Widget _buildPodcastListItem(PodcastModel podcast) {
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
                image: NetworkImage(podcast.imageUrl),
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
                  podcast.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  podcast.host,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${podcast.category} • Episode ${podcast.episodeNumber} • ${_formatDuration(podcast.duration)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openPodcastPlayer(podcast),
            icon: const Icon(Icons.play_circle_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesCard(Map<String, dynamic> series) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => print('Series ${series['title']} tapped'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(series['imageUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  series['title'],
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
                  series['host'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${series['episodes']} episodes',
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Filter Podcasts',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose your preferences',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            // Add filter options here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}
