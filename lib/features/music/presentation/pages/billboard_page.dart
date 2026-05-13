import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/music_model.dart';
import '../../../../data/services/home_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/providers/audio_provider.dart';
import '../../../../ui/widgets/player_screen.dart';
import '../../../../core/config/api_config.dart';

class BillboardPage extends StatefulWidget {
  const BillboardPage({Key? key}) : super(key: key);

  @override
  State<BillboardPage> createState() => _BillboardPageState();
}

class _BillboardPageState extends State<BillboardPage> {
  late HomeService _homeService;
  List<MusicModel> _songs = [];
  bool _isLoading = true;
  String _period = 'week';

  @override
  void initState() {
    super.initState();
    _homeService = HomeService(apiClient: context.read<ApiClient>());
    _loadBillboard();
  }

  Future<void> _loadBillboard() async {
    setState(() => _isLoading = true);
    try {
      final songs = await _homeService.getTrendingSongs();
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else
            _buildBillboardList(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'BILLBOARD HOT 100',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    const Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
            Center(
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.show_chart, size: 150, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onSelected: (value) {
            setState(() => _period = value);
            _loadBillboard();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'day', child: Text('Daily')),
            const PopupMenuItem(value: 'week', child: Text('Weekly')),
            const PopupMenuItem(value: 'month', child: Text('Monthly')),
          ],
        ),
      ],
    );
  }

  Widget _buildBillboardList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = _songs[index];
            return _BillboardListItem(song: song, rank: index + 1, total: _songs.length);
          },
          childCount: _songs.length,
        ),
      ),
    );
  }
}

class _BillboardListItem extends StatelessWidget {
  final MusicModel song;
  final int rank;
  final int total;

  const _BillboardListItem({
    Key? key,
    required this.song,
    required this.rank,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;

    return GestureDetector(
      onTap: () {
        context.read<AudioProvider>().playMusic(song);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PlayerScreen(music: song),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTop3 ? AppColors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: isTop3 ? AppColors.primary : Colors.white.withOpacity(0.5),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                ApiConfig.resolveUrl(song.imageUrl),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.music_note, color: Colors.white24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isTop3)
              Icon(Icons.trending_up, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.play_circle_fill, color: AppColors.primary.withOpacity(0.8), size: 28),
              onPressed: () {
                context.read<AudioProvider>().playMusic(song);
              },
            ),
          ],
        ),
      ),
    );
  }
}
