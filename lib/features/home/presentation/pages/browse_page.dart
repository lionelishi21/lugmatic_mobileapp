import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/music_model.dart';
import '../../../../data/models/artist_model.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({Key? key}) : super(key: key);

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  List<Map<String, dynamic>> _genres = [];
  List<MusicModel> _searchResults = [];
  List<ArtistModel> _artistResults = [];
  List<MusicModel> _newReleases = [];
  bool _isSearching = false;
  bool _isLoading = true;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final apiClient = context.read<ApiClient>();
    setState(() => _isLoading = true);
    try {
      final genreRes = await apiClient.dio.get(ApiConfig.genres);
      final genreBody = genreRes.data;
      final genreItems = genreBody['data'] ?? genreBody['genres'] ?? [];

      final songRes = await apiClient.dio.get(
        ApiConfig.songs,
        queryParameters: {'limit': 10, 'sort': '-createdAt'},
      );
      final songBody = songRes.data;
      final songItems = songBody['data'] ?? songBody['songs'] ?? [];

      if (mounted) {
        setState(() {
          _genres = List<Map<String, dynamic>>.from(genreItems);
          _newReleases = (songItems as List)
              .map((json) => MusicModel.fromJson(json as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _artistResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    final apiClient = context.read<ApiClient>();
    try {
      final res = await apiClient.dio.get(
        ApiConfig.search,
        queryParameters: {'q': query},
      );
      final body = res.data;
      final data = body['data'] ?? body;

      final songs = data['songs'] ?? [];
      final artists = data['artists'] ?? [];

      if (mounted) {
        setState(() {
          _searchResults = (songs as List)
              .map((j) => MusicModel.fromJson(j as Map<String, dynamic>))
              .toList();
          _artistResults = (artists as List)
              .map((j) => ArtistModel.fromJson(j as Map<String, dynamic>))
              .toList();
          _isSearching = false;
          _searchQuery = query;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
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
                if (_searchQuery.isNotEmpty) ...[
                  _buildSearchResultsSection(),
                ] else if (_isLoading) ...[
                  const SizedBox(height: 100),
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                ] else ...[
                  _buildCategoryTabs(),
                  const SizedBox(height: 32),
                  _buildGenresGrid(),
                  const SizedBox(height: 32),
                  _buildNewReleases(),
                  const SizedBox(height: 100),
                ],
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
      backgroundColor: const Color(0xFF111827),
      elevation: 0,
      title: const Text(
        'Browse',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.filter_list, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          onSubmitted: _performSearch,
          decoration: InputDecoration(
            hintText: 'Search for songs, artists, albums...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withOpacity(0.6),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.6)),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsSection() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_artistResults.isNotEmpty) ...[
            Text(
              'Artists (${_artistResults.length})',
              style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...(_artistResults.take(5).map((a) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage: a.imageUrl.isNotEmpty ? NetworkImage(a.imageUrl) : null,
                    child: a.imageUrl.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(a.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(a.genres.join(', '), style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                ))),
            const SizedBox(height: 24),
          ],
          if (_searchResults.isNotEmpty) ...[
            Text(
              'Songs (${_searchResults.length})',
              style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...(_searchResults.take(10).map((s) => ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF10B981).withOpacity(0.2),
                    ),
                    child: s.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(s.imageUrl, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white)),
                          )
                        : const Icon(Icons.music_note, color: Colors.white),
                  ),
                  title: Text(s.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(s.artist, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                  trailing: const Icon(Icons.play_circle_outline, color: Color(0xFF10B981)),
                ))),
          ],
          if (_searchResults.isEmpty && _artistResults.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: Text(
                  'No results for "$_searchQuery"',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                ),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['All', ..._genres.map((g) => g['name']?.toString() ?? '').where((n) => n.isNotEmpty).take(8)];
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenresGrid() {
    final genreIcons = <String, IconData>{
      'pop': Icons.star,
      'rock': Icons.music_note,
      'hip-hop': Icons.headphones,
      'jazz': Icons.piano,
      'classical': Icons.library_music,
      'electronic': Icons.waves,
      'r&b': Icons.favorite,
      'reggae': Icons.surround_sound,
      'dancehall': Icons.nightlife,
      'afrobeats': Icons.music_video,
    };

    final genreColors = [
      const Color(0xFFEC4899),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF06B6D4),
      const Color(0xFFE11D48),
    ];

    final displayGenres = _genres.take(8).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse by Genre',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: displayGenres.length,
            itemBuilder: (context, index) {
              final genre = displayGenres[index];
              final name = genre['name']?.toString() ?? 'Unknown';
              final color = genreColors[index % genreColors.length];
              final icon = genreIcons[name.toLowerCase()] ?? Icons.music_note;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.8),
                      color.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(icon, color: Colors.white, size: 32),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewReleases() {
    if (_newReleases.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Releases',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _newReleases.length.clamp(0, 5),
            itemBuilder: (context, index) {
              final song = _newReleases[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF10B981).withOpacity(0.2),
                      ),
                      child: song.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(song.imageUrl, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.album, color: Colors.white, size: 30)),
                            )
                          : const Icon(Icons.album, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Color(0xFF10B981),
                        size: 32,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
