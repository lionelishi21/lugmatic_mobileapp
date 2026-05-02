import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lugmatic_flutter/core/network/api_client.dart';
import 'package:lugmatic_flutter/data/models/artist_model.dart';
import 'package:lugmatic_flutter/data/services/home_service.dart';
import 'package:lugmatic_flutter/core/constants/app_colors.dart';
import 'package:lugmatic_flutter/core/config/api_config.dart';

class MeetArtistPage extends StatefulWidget {
  const MeetArtistPage({Key? key}) : super(key: key);

  @override
  State<MeetArtistPage> createState() => _MeetArtistPageState();
}

class _MeetArtistPageState extends State<MeetArtistPage> {
  final TextEditingController _searchController = TextEditingController();
  late HomeService _homeService;
  
  bool _isLoading = true;
  bool _isSearching = false;

  List<ArtistModel> _artists = [];
  List<ArtistModel> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _homeService = HomeService(apiClient: context.read<ApiClient>());
    _loadArtists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadArtists() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final artists = await _homeService.getFeaturedArtists();
      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() { _isSearching = false; _searchResults = []; });
      return;
    }
    
    // Simple local search for now. If backend supports artist search, replace this.
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _isSearching = true);
      
      final q = query.trim().toLowerCase();
      final results = _artists.where((a) => a.name.toLowerCase().contains(q)).toList();
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final showSearch = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: RefreshIndicator(
        onRefresh: _loadArtists,
        color: const Color(0xFF10B981),
        backgroundColor: const Color(0xFF1F2937),
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
                ],
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
              )
            else if (showSearch)
              _buildGrid(_searchResults)
            else
              _buildGrid(_artists),
          ],
        ),
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
        'Meet Artists',
        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
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
        decoration: InputDecoration(
          hintText: 'Search for your favorite artists...',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white60),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white60, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() { _searchResults = []; _isSearching = false; });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildGrid(List<ArtistModel> items) {
    if (items.isEmpty && !_isSearching) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No artists found', style: TextStyle(color: Colors.white54)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final artist = items[index];
            return _buildArtistCard(artist);
          },
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildArtistCard(ArtistModel artist) {
    final isLive = artist.isLive;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/artist', arguments: {'id': artist.id, 'initialData': artist}),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: artist.imageUrl.isNotEmpty
                        ? Image.network(
                            ApiConfig.resolveUrl(artist.imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderAvatar(),
                          )
                        : _placeholderAvatar(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              artist.name,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (artist.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: AppColors.primary, size: 14),
                          ]
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${artist.followers} fans',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isLive)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                      SizedBox(width: 4),
                      Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      color: Colors.white10,
      child: const Icon(Icons.person, color: Colors.white38, size: 48),
    );
  }
}
