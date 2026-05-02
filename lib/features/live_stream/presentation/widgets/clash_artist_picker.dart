import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/live_stream_model.dart';
import '../../../../data/services/live_stream_service.dart';
import '../../../../core/theme/neumorphic_theme.dart';

class ClashArtistPicker extends StatefulWidget {
  final String currentStreamId;
  const ClashArtistPicker({Key? key, required this.currentStreamId}) : super(key: key);

  @override
  State<ClashArtistPicker> createState() => _ClashArtistPickerState();
}

class _ClashArtistPickerState extends State<ClashArtistPicker> {
  bool _isLoading = true;
  List<LiveStreamModel> _activeStreams = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLiveArtists();
  }

  Future<void> _fetchLiveArtists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final liveStreamService = context.read<LiveStreamService>();
      final streams = await liveStreamService.getLiveStreams(status: 'live');
      
      if (mounted) {
        setState(() {
          // Filter out the current artist's own stream
          _activeStreams = streams.where((s) => s.id != widget.currentStreamId).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load live artists';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: NeumorphicTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: NeumorphicTheme.textTertiary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'CHOOSE OPPONENT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Artists currently live and ready to clash',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: NeumorphicTheme.primaryAccent))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white30)))
                    : _activeStreams.isEmpty
                        ? const Center(child: Text('No other artists live right now', style: TextStyle(color: Colors.white30)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _activeStreams.length,
                            itemBuilder: (context, index) {
                              final stream = _activeStreams[index];
                              return _buildArtistItem(stream);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistItem(LiveStreamModel stream) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: stream.host?.image.isNotEmpty == true 
              ? NetworkImage(stream.host!.image) 
              : null,
          child: stream.host?.image.isNotEmpty != true 
              ? const Icon(Icons.person, color: Colors.white54) 
              : null,
        ),
        title: Text(
          stream.host?.name ?? 'Unknown Artist',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          stream.title,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: ElevatedButton(
          onPressed: () => Navigator.pop(context, stream.host?.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('INVITE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
