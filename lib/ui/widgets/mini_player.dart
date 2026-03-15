import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/providers/audio_provider.dart';
import 'player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final music = audioProvider.currentMusic;
        // Don't show if there's no music or if playback explicitly stopped
        if (music == null || audioProvider.position == Duration.zero && !audioProvider.isPlaying && audioProvider.duration == Duration.zero) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 88, left: 8, right: 8, top: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => PlayerScreen(music: music),
                );
              },
              child: SizedBox(
                height: 64, // Slightly shorter for better aesthetics
                child: Row(
                  children: [
                    // Album Art
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: music.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                    
                    // Song Info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            music.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            music.artist,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Progress Indicator & Play/Pause
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              value: audioProvider.duration.inSeconds > 0
                                  ? audioProvider.position.inSeconds / audioProvider.duration.inSeconds
                                  : 0,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                              strokeWidth: 2,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            icon: Icon(
                              audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: () {
                              if (audioProvider.isPlaying) {
                                audioProvider.pause();
                              } else {
                                audioProvider.resume();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Close Button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 48),
                      icon: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.6),
                        size: 20,
                      ),
                      onPressed: () {
                        audioProvider.stop();
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
