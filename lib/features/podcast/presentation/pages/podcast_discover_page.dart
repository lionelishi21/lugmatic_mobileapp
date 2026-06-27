import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/podcast_model.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/data/providers/audio_provider.dart';
import 'package:lugmatic_flutter/data/services/podcast_service.dart';
import 'package:lugmatic_flutter/core/network/api_exception.dart';
import 'package:lugmatic_flutter/ui/widgets/player_screen.dart';
import 'package:provider/provider.dart';

class PodcastDiscoverPage extends StatefulWidget {
  const PodcastDiscoverPage({Key? key}) : super(key: key);

  @override
  State<PodcastDiscoverPage> createState() => _PodcastDiscoverPageState();
}

class _PodcastDiscoverPageState extends State<PodcastDiscoverPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;
  List<PodcastModel> _trendingPodcasts = [];
  List<PodcastModel> _podcasts = [];

  static const List<String> _categories = [
    'Technology', 'Health & Wellness', 'Business', 'Science', 'Arts',
    'Education', 'Entertainment', 'News', 'Sports', 'True Crime', 'Comedy', 'Fiction'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final podcastService = context.read<PodcastService>();
      final results = await Future.wait([
        podcastService.getTrendingPodcasts(),
        podcastService.getPodcasts(
          search: _searchController.text.trim(),
          category: _selectedCategory,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _trendingPodcasts = results[0];
        _podcasts = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Failed to load podcasts';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  void _onCategoryTap(String category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? null : category;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
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
                  _buildContent(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_trendingPodcasts.isEmpty && _podcasts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text(
            'No podcasts found',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_trendingPodcasts.isNotEmpty) ...[
          _buildSectionHeader('Trending Podcasts'),
          const SizedBox(height: 16),
          _buildTrendingPodcasts(),
          const SizedBox(height: 32),
        ],
        if (_podcasts.isNotEmpty) ...[
          _buildSectionHeader(_selectedCategory != null || _searchController.text.isNotEmpty
              ? 'Results'
              : 'All Podcasts'),
          const SizedBox(height: 16),
          _buildPodcastList(),
        ],
      ],
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
        onChanged: _onSearchChanged,
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
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => _onCategoryTap(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          category,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
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

  Widget _buildPodcastList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _podcasts.map((podcast) => _buildPodcastListItem(podcast)).toList(),
      ),
    );
  }

  Widget _buildPodcastCard(PodcastModel podcast) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.08),
                    image: podcast.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(podcast.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: podcast.imageUrl.isEmpty
                      ? Icon(Icons.podcasts, color: Colors.white.withValues(alpha: 0.4), size: 32)
                      : null,
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
                    color: Colors.white.withValues(alpha: 0.7),
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
                      color: Colors.green.withValues(alpha: 0.7),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      podcast.category,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
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

  Widget _buildPodcastListItem(PodcastModel podcast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withValues(alpha: 0.08),
              image: podcast.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(podcast.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: podcast.imageUrl.isEmpty
                ? Icon(Icons.podcasts, color: Colors.white.withValues(alpha: 0.4))
                : null,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  podcast.host,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${podcast.category} • ${_formatDuration(podcast.duration)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
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

  void _openPodcastPlayer(PodcastModel podcast) {
    if (podcast.audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This podcast has no playable episode yet')),
      );
      return;
    }

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

    context.read<AudioProvider>().playMusic(musicModel);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerScreen(music: musicModel),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
