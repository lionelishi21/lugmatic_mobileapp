import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/music_model.dart';
import '../../data/providers/audio_provider.dart';

/// Line-synced karaoke lyrics: highlights and scrolls to the line matching
/// the current playback position, driven by [AudioProvider.position].
class KaraokeLyricsView extends StatefulWidget {
  final List<LyricLine> lines;

  const KaraokeLyricsView({Key? key, required this.lines}) : super(key: key);

  @override
  State<KaraokeLyricsView> createState() => _KaraokeLyricsViewState();
}

class _KaraokeLyricsViewState extends State<KaraokeLyricsView> {
  static const double _itemHeight = 56.0;
  static const double _viewportHeight = 320.0;

  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  int _activeIndexFor(Duration position) {
    int active = -1;
    for (var i = 0; i < widget.lines.length; i++) {
      if (widget.lines[i].time <= position) {
        active = i;
      } else {
        break;
      }
    }
    return active;
  }

  void _scrollToActive(int index) {
    if (!_scrollController.hasClients || index < 0) return;
    final target = (index * _itemHeight) - (_viewportHeight / 2) + (_itemHeight / 2);
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, _) {
        final activeIndex = _activeIndexFor(audioProvider.position);
        if (activeIndex != _lastActiveIndex) {
          _lastActiveIndex = activeIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive(activeIndex));
        }

        return SizedBox(
          height: _viewportHeight,
          child: ListView.builder(
            controller: _scrollController,
            itemExtent: _itemHeight,
            itemCount: widget.lines.length,
            itemBuilder: (context, index) {
              final isActive = index == activeIndex;
              final isPast = index < activeIndex;

              return Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: isActive ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, t, child) {
                    final opacity = (isPast ? 0.35 : 0.5 + 0.5 * t).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: 1.0 + (0.12 * t),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.lines[index].text,
                          style: TextStyle(
                            color: isActive ? const Color(0xFF10B981) : Colors.white,
                            fontSize: isActive ? 22 : 17,
                            fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                            shadows: isActive
                                ? [Shadow(color: const Color(0xFF10B981).withValues(alpha: 0.6 * t), blurRadius: 16)]
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
