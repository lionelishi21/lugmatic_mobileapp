import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/genre_model.dart';
import '../../../../data/services/music_service.dart';
import '../../../../core/network/api_client.dart';

class GenreListPage extends StatefulWidget {
  const GenreListPage({Key? key}) : super(key: key);

  @override
  State<GenreListPage> createState() => _GenreListPageState();
}

class _GenreListPageState extends State<GenreListPage> {
  late MusicService _musicService;
  List<GenreModel> _genres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _musicService = MusicService(apiClient: context.read<ApiClient>());
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    setState(() => _isLoading = true);
    try {
      final genres = await _musicService.getGenres();
      if (mounted) {
        setState(() {
          _genres = genres;
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'GENRES',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: _genres.length,
              itemBuilder: (context, index) => _GenreCard(genre: _genres[index]),
            ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  final GenreModel genre;

  const _GenreCard({Key? key, required this.genre}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parse color string if exists, else use random-ish decent colors
    final bgColor = _getGenreColor(genre.color);

    return GestureDetector(
      onTap: () {
        // Navigate to discovery page with this genre
        Navigator.pushNamed(context, '/trending', arguments: {'genre': genre.name});
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgColor.withOpacity(0.8), bgColor.withOpacity(0.4)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: bgColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.music_note, size: 80, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    genre.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  Text(
                    '${genre.songCount} songs',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGenreColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      // Fallback colors based on genre name hash
      final colors = [
        Colors.pinkAccent,
        Colors.purpleAccent,
        Colors.deepOrangeAccent,
        Colors.indigoAccent,
        Colors.tealAccent,
        Colors.amberAccent,
      ];
      return colors[genre.name.length % colors.length];
    }
    try {
      final hex = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blueAccent;
    }
  }
}
