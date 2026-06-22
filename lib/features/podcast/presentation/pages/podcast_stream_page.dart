import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/podcast_model.dart';
import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/data/providers/audio_provider.dart';
import 'package:lugmatic_flutter/data/services/podcast_service.dart';
import 'package:lugmatic_flutter/core/network/api_exception.dart';
import 'package:lugmatic_flutter/ui/widgets/player_screen.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/comment_section_widget.dart';

class PodcastStreamPage extends StatefulWidget {
  const PodcastStreamPage({Key? key}) : super(key: key);

  @override
  State<PodcastStreamPage> createState() => _PodcastStreamPageState();
}

class _PodcastStreamPageState extends State<PodcastStreamPage> {
  bool _isLoading = true;
  String? _error;
  List<PodcastModel> _trendingPodcasts = [];
  List<PodcastModel> _allPodcasts = [];

  @override
  void initState() {
    super.initState();
    _loadPodcasts();
  }

  Future<void> _loadPodcasts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final podcastService = context.read<PodcastService>();
      final results = await Future.wait([
        podcastService.getTrendingPodcasts(),
        podcastService.getPodcasts(),
      ]);
      if (!mounted) return;
      setState(() {
        _trendingPodcasts = results[0];
        _allPodcasts = results[1];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: RefreshIndicator(
        onRefresh: _loadPodcasts,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
        child: Column(
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPodcasts,
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

    if (_trendingPodcasts.isEmpty && _allPodcasts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Center(
          child: Text(
            'No podcasts available yet',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        if (_trendingPodcasts.isNotEmpty) ...[
          _buildSectionHeader('Trending'),
          const SizedBox(height: 16),
          _buildPodcastRow(_trendingPodcasts),
          const SizedBox(height: 32),
        ],
        if (_allPodcasts.isNotEmpty) ...[
          _buildSectionHeader('All Podcasts'),
          const SizedBox(height: 16),
          _buildPodcastRow(_allPodcasts),
          const SizedBox(height: 32),
        ],
        const SizedBox(height: 100),
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
        'Podcasts',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
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

  Widget _buildPodcastRow(List<PodcastModel> podcasts) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: podcasts.length,
        itemBuilder: (context, index) {
          final podcast = podcasts[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            child: _buildPodcastCard(podcast),
          );
        },
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
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.08),
                    image: podcast.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(podcast.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: podcast.imageUrl.isEmpty
                      ? Icon(Icons.podcasts, color: Colors.white.withOpacity(0.4), size: 32)
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
                      Icons.play_circle_outline,
                      color: Colors.white.withOpacity(0.5),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatNumber(podcast.playCount)} plays',
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

  void _openPodcastPlayer(PodcastModel podcast) {
    if (podcast.episodes.isEmpty && podcast.audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This podcast has no playable episodes yet')),
      );
      return;
    }

    // If multiple episodes, show episode picker; otherwise play directly
    if (podcast.episodes.length > 1) {
      _showEpisodeSheet(podcast);
    } else {
      _playEpisode(podcast, podcast.episodes.isNotEmpty ? podcast.episodes.first : null);
    }
  }

  void _showEpisodeSheet(PodcastModel podcast) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: podcast.imageUrl.isNotEmpty
                        ? Image.network(podcast.imageUrl, width: 48, height: 48, fit: BoxFit.cover)
                        : Container(width: 48, height: 48, color: Colors.white12,
                            child: const Icon(Icons.podcasts, color: Colors.white54)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(podcast.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${podcast.episodes.length} episodes',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: podcast.episodes.length,
                itemBuilder: (context, index) {
                  final ep = podcast.episodes[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      child: Text('${ep.episodeNumber}',
                          style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 12)),
                    ),
                    title: Text(ep.title,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(_formatDuration(ep.duration),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                    trailing: const Icon(Icons.play_circle_outline, color: Color(0xFF8B5CF6)),
                    onTap: () {
                      Navigator.pop(context);
                      _playEpisode(podcast, ep);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playEpisode(PodcastModel podcast, PodcastEpisode? episode) {
    final audioUrl = episode?.audioUrl ?? podcast.audioUrl;
    if (audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio available for this episode')),
      );
      return;
    }

    final musicModel = MusicModel(
      id: episode?.id ?? podcast.id,
      title: episode != null ? '${podcast.title} — ${episode.title}' : podcast.title,
      artist: podcast.host,
      album: podcast.seriesTitle,
      imageUrl: podcast.imageUrl,
      audioUrl: audioUrl,
      duration: episode?.duration ?? podcast.duration,
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
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m';
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
