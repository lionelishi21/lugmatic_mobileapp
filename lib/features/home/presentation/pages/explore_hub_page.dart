import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/core/constants/app_colors.dart';
import 'package:lugmatic_flutter/features/music/presentation/pages/music_hub_page.dart';
import 'package:lugmatic_flutter/features/podcast/presentation/pages/podcast_hub_page.dart';
import 'package:lugmatic_flutter/features/live_stream/presentation/pages/tiktok_live_page.dart';
import 'package:lugmatic_flutter/features/store/presentation/pages/store_page.dart';
import 'package:lugmatic_flutter/features/mixer/presentation/pages/mixer_page.dart';
import 'package:lugmatic_flutter/shared/widgets/demand_artist_dialog.dart';
import 'package:lugmatic_flutter/features/home/presentation/pages/browse_page.dart';

class ExploreHubPage extends StatelessWidget {
  const ExploreHubPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF064E3B), // Dark Green tint (OKLCH 0.13)
              Color(0xFF0F172A), // Dark Slate (OKLCH 0.10)
              Color(0xFF000000), // Black (OKLCH 0.09)
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildSearchBar(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate([
                _buildHubCard(
                  context,
                  title: 'Discover Songs',
                  icon: Icons.music_note,
                  color: AppColors.primary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicHubPage())),
                ),
                _buildHubCard(
                  context,
                  title: 'Meet Artists',
                  icon: Icons.people,
                  color: AppColors.secondary,
                  onTap: () {
                    // Navigate to Artists Hub if it exists, or Home with filter
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Artist Discovery coming soon!')),
                    );
                  },
                ),
                _buildHubCard(
                  context,
                  title: 'Watch Videos',
                  icon: Icons.play_circle_fill,
                  color: AppColors.error,
                  onTap: () {
                    // Navigate to Video Hub
                  },
                ),
                _buildHubCard(
                  context,
                  title: 'AI Mixer',
                  icon: Icons.auto_awesome,
                  color: AppColors.primary,
                  onTap: () => Navigator.pushNamed(context, '/mixer'),
                ),
                _buildHubCard(
                  context,
                  title: 'Podcasts',
                  icon: Icons.mic,
                  color: const Color(0xFFF59E0B),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PodcastHubPage())),
                ),
                _buildHubCard(
                  context,
                  title: 'Live Now',
                  icon: Icons.live_tv_rounded,
                  color: AppColors.error,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TikTokLivePage())),
                ),
                _buildHubCard(
                  context,
                  title: 'Get Coins',
                  icon: Icons.monetization_on,
                  color: const Color(0xFFFFD700),
                  onTap: () => Navigator.pushNamed(context, '/store'),
                ),
                _buildHubCard(
                  context,
                  title: 'Request Artist',
                  icon: Icons.person_add_alt_1_rounded,
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const DemandArtistDialog(),
                    );
                  },
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      title: const Text(
        'Explore',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/store'),
          icon: const Icon(Icons.monetization_on, color: Color(0xFFFFD700)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrowsePage())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 20),
              const SizedBox(width: 12),
              Text(
                'Search for songs, artists...',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
