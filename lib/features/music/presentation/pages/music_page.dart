import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/features/music/data/music_model.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({Key? key}) : super(key: key);

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  final PageController _pageController = PageController();

  final List<MusicModel> _trendingSongs = [
    MusicModel(
      id: '1',
      title: 'Midnight Dreams',
      artist: 'Luna Nova',
      album: 'Cosmic Vibes',
      imageUrl: 'assets/images/music_background_1.jpg',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      duration: const Duration(minutes: 3, seconds: 45),
      genre: 'Electronic',
      releaseDate: DateTime.now().subtract(const Duration(days: 5)),
    ),
    MusicModel(
      id: '2',
      title: 'Ocean Waves',
      artist: 'Marine Sounds',
      album: 'Nature Therapy',
      imageUrl: 'assets/images/music_background_2.jpg',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      duration: const Duration(minutes: 4, seconds: 12),
      genre: 'Ambient',
      releaseDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [
          _buildTrendingSongs(),
        ],
      ),
    );
  }

  Widget _buildTrendingSongs() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _trendingSongs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final song = _trendingSongs[index];
        return _buildSongItem(song);
      },
    );
  }

  Widget _buildSongItem(MusicModel song) {
    return Material(
      color: Colors.white.withOpacity(0.02),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Implement song tap logic
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  song.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(width: 50, height: 50, color: Colors.grey[300]),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}