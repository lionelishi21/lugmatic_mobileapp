import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/providers/audio_provider.dart';
import '../../shared/widgets/gift_bottom_sheet.dart';
import 'player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        final music = audio.currentMusic;
        if (music == null) return const SizedBox.shrink();

        final progress = audio.duration.inMilliseconds > 0
            ? (audio.position.inMilliseconds / audio.duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => PlayerScreen(music: music),
          ),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5),
              ),
            ),
            child: Column(
              children: [
                // Progress bar — thin green line at the very top
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  minHeight: 2,
                ),

                // Main content row
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // Album Art
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: music.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: music.imageUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => _artPlaceholder(),
                                )
                              : _artPlaceholder(),
                        ),
                        const SizedBox(width: 10),

                        // Song info — expands and clips
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                music.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                music.artist,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Gift button
                        _ControlButton(
                          icon: Icons.card_giftcard_rounded,
                          color: const Color(0xFF10B981),
                          size: 20,
                          onTap: () => GiftBottomSheet.show(
                            context,
                            artistId: music.artistId,
                            artistName: music.artist,
                          ),
                        ),
                        const SizedBox(width: 2),

                        // Previous
                        _ControlButton(
                          icon: Icons.skip_previous_rounded,
                          onTap: audio.previous,
                        ),

                        // Play / Pause
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: GestureDetector(
                            onTap: () {
                              if (audio.isPlaying) {
                                audio.pause();
                              } else {
                                audio.resume();
                              }
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                              child: audio.isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      audio.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                            ),
                          ),
                        ),

                        // Next
                        _ControlButton(
                          icon: Icons.skip_next_rounded,
                          onTap: audio.next,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _artPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      color: const Color(0xFF2D2D44),
      child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 22),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
