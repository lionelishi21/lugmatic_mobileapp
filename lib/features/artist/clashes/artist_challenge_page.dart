import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/clash_pool_model.dart';
import '../../../data/services/regular_clash_service.dart';
import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

class ArtistChallengePage extends StatefulWidget {
  const ArtistChallengePage({super.key});

  @override
  State<ArtistChallengePage> createState() => _ArtistChallengePageState();
}

class _ArtistChallengePageState extends State<ArtistChallengePage> {
  late RegularClashService _service;
  late ApiClient _apiClient;

  ClashPoolModel? _activePool;
  bool _isLoadingPool = true;
  bool _isSending = false;
  String? _poolError;

  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedArtist;
  bool _isSearching = false;
  String _selectedRealm = 'fire';

  static const _realms = ['fire', 'ice', 'reggae', 'dancehall', 'hiphop', 'rnb', 'afrobeats'];

  @override
  void initState() {
    super.initState();
    _service = RegularClashService(apiClient: context.read());
    _apiClient = context.read();
    _loadPool();
  }

  Future<void> _loadPool() async {
    setState(() { _isLoadingPool = true; _poolError = null; });
    try {
      final pools = await _service.getActivePools();
      if (mounted) {
        final openPool = pools.where((p) => p.isOpen).toList();
        setState(() {
          _activePool = openPool.isNotEmpty ? openPool.first : null;
          _isLoadingPool = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _poolError = e.toString(); _isLoadingPool = false; });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _searchArtists(query.trim()));
  }

  Future<void> _searchArtists(String query) async {
    setState(() => _isSearching = true);
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.artists,
        queryParameters: {'search': query, 'limit': 10},
      );
      final data = response.data['data'] ?? response.data;
      final items = data is List ? data : (data['artists'] ?? data['items'] ?? []);
      if (mounted) setState(() { _searchResults = List<Map<String, dynamic>>.from(items); _isSearching = false; });
    } on DioException catch (_) {
      if (mounted) setState(() { _searchResults = []; _isSearching = false; });
    }
  }

  Future<void> _sendChallenge() async {
    final pool = _activePool;
    final opponent = _selectedArtist;
    if (pool == null || opponent == null) return;
    setState(() => _isSending = true);
    try {
      await _service.sendChallenge(
        poolId: pool.id,
        opponentArtistId: opponent['_id']?.toString() ?? opponent['id']?.toString() ?? '',
        realm: _selectedRealm,
        message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge sent!'), backgroundColor: AppColors.primary),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text('Challenge an Artist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingPool
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _activePool == null
              ? _buildNoPool()
              : _buildForm(),
    );
  }

  Widget _buildNoPool() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No challenge period is currently open.',
              style: TextStyle(color: Colors.white54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (_poolError != null) ...[
              const SizedBox(height: 8),
              Text(_poolError!, style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final pool = _activePool!;
    final remaining = pool.challengeDeadline.difference(DateTime.now());
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pool info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.15), AppColors.secondary.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pool.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Season ${pool.season} • $days d $hours h left to challenge',
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Artist search
          const Text('Search Artist', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_selectedArtist != null)
            _SelectedArtistChip(
              artist: _selectedArtist!,
              onRemove: () => setState(() { _selectedArtist = null; _searchController.clear(); _searchResults = []; }),
            )
          else ...[
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type artist name...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppColors.card,
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon: _isSearching
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length.clamp(0, 5),
                  separatorBuilder: (_, __) => Divider(color: AppColors.border, height: 1),
                  itemBuilder: (context, i) {
                    final artist = _searchResults[i];
                    final imgUrl = artist['image']?.toString();
                    return ListTile(
                      onTap: () => setState(() {
                        _selectedArtist = artist;
                        _searchController.clear();
                        _searchResults = [];
                      }),
                      leading: CircleAvatar(
                        backgroundImage: imgUrl != null ? NetworkImage(ApiConfig.resolveUrl(imgUrl)) : null,
                        child: imgUrl == null ? const Icon(Icons.person, size: 16) : null,
                      ),
                      title: Text(artist['name'] ?? '', style: const TextStyle(color: Colors.white)),
                      subtitle: Text(artist['genre'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    );
                  },
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),

          // Realm picker
          const Text('Realm', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _realms.map((realm) {
              final isSelected = _selectedRealm == realm;
              return GestureDetector(
                onTap: () => setState(() => _selectedRealm = realm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(
                    realm.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Message
          const Text('Message (optional)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLength: 200,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add a trash-talk message...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              counterStyle: const TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedArtist == null || _isSending ? null : _sendChallenge,
              icon: _isSending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.bolt),
              label: Text(_isSending ? 'Sending...' : 'Send Challenge', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedArtistChip extends StatelessWidget {
  final Map<String, dynamic> artist;
  final VoidCallback onRemove;

  const _SelectedArtistChip({required this.artist, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final imgUrl = artist['image']?.toString();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: imgUrl != null ? NetworkImage(ApiConfig.resolveUrl(imgUrl)) : null,
            child: imgUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(artist['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
          ),
        ],
      ),
    );
  }
}
