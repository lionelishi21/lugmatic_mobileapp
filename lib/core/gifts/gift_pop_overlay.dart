import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import 'gift_pop_controller.dart';

class _TierConfig {
  final Duration duration;
  final int particleCount;
  final double particleSpread;
  final int ringCount;
  final Color glow;
  final List<Color> particleColors;
  final double badgeSize;
  final double textSize;
  final String label;
  final bool flash;
  final bool crown;

  const _TierConfig({
    required this.duration,
    required this.particleCount,
    required this.particleSpread,
    required this.ringCount,
    required this.glow,
    required this.particleColors,
    required this.badgeSize,
    required this.textSize,
    required this.label,
    required this.flash,
    required this.crown,
  });
}

const _accent = Color(0xFF86E560);
const _gold = Color(0xFFFFD25A);

const Map<GiftPopTier, _TierConfig> _tierConfigs = {
  GiftPopTier.low: _TierConfig(
    duration: Duration(milliseconds: 1600),
    particleCount: 6,
    particleSpread: 50,
    ringCount: 1,
    glow: _accent,
    particleColors: [_accent, Colors.white],
    badgeSize: 92,
    textSize: 14,
    label: '',
    flash: false,
    crown: false,
  ),
  GiftPopTier.mid: _TierConfig(
    duration: Duration(milliseconds: 2400),
    particleCount: 14,
    particleSpread: 90,
    ringCount: 2,
    glow: _accent,
    particleColors: [_accent, Color(0xFF5FB83F), Colors.white],
    badgeSize: 116,
    textSize: 16,
    label: 'NICE GIFT!',
    flash: false,
    crown: false,
  ),
  GiftPopTier.high: _TierConfig(
    duration: Duration(milliseconds: 3600),
    particleCount: 26,
    particleSpread: 140,
    ringCount: 3,
    glow: _gold,
    particleColors: [_gold, _accent, Color(0xFFFF8A3D), Colors.white],
    badgeSize: 150,
    textSize: 20,
    label: 'MASSIVE GIFT',
    flash: true,
    crown: true,
  ),
};

/// Mount once near the app root (e.g. in MaterialApp.builder) so it overlays
/// on top of whatever screen is showing when a gift fires.
class GiftPopOverlayHost extends StatelessWidget {
  const GiftPopOverlayHost({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GiftPopController.instance,
      builder: (context, _) {
        final event = GiftPopController.instance.event;
        if (event == null) return const SizedBox.shrink();
        return IgnorePointer(
          child: _GiftPopVisual(
            key: ValueKey(GiftPopController.instance.seq),
            event: event,
          ),
        );
      },
    );
  }
}

class _GiftPopVisual extends StatefulWidget {
  final GiftPopEvent event;
  const _GiftPopVisual({super.key, required this.event});

  @override
  State<_GiftPopVisual> createState() => _GiftPopVisualState();
}

class _GiftPopVisualState extends State<_GiftPopVisual> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<double> _angles;
  late final List<double> _distances;
  late final List<double> _sizes;
  late final List<Color> _colors;

  _TierConfig get _cfg => _tierConfigs[widget.event.tier]!;

  @override
  void initState() {
    super.initState();
    final cfg = _cfg;
    _controller = AnimationController(vsync: this, duration: cfg.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          GiftPopController.instance.clear();
        }
      })
      ..forward();

    final rnd = Random();
    _angles = List.generate(cfg.particleCount, (i) => (i / cfg.particleCount) * 2 * pi + rnd.nextDouble() * 0.3);
    _distances = List.generate(cfg.particleCount, (_) => cfg.particleSpread * (0.6 + rnd.nextDouble() * 0.6));
    _sizes = List.generate(cfg.particleCount, (_) => widget.event.tier == GiftPopTier.high ? 5 + rnd.nextDouble() * 6 : 3 + rnd.nextDouble() * 4);
    _colors = List.generate(cfg.particleCount, (i) => cfg.particleColors[i % cfg.particleColors.length]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    final imageUrl = widget.event.giftImageUrl != null && widget.event.giftImageUrl!.isNotEmpty
        ? ApiConfig.resolveUrl(widget.event.giftImageUrl)
        : null;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // Badge: overshoot pop-in then hold, fade near the very end.
        final badgeT = Curves.easeOutBack.transform((t * 1.6).clamp(0, 1).toDouble());
        final fadeT = t > 0.82 ? 1 - ((t - 0.82) / 0.18) : 1.0;
        final particleT = Curves.easeOut.transform(t);

        return Stack(
          children: [
            if (cfg.flash)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: cfg.glow.withValues(alpha: (1 - t) * 0.35 * (t < 0.25 ? (t / 0.25) : 1)),
                  ),
                ),
              ),
            Center(
              child: Opacity(
                opacity: fadeT.clamp(0, 1).toDouble(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Expanding shockwave rings
                    for (int i = 0; i < cfg.ringCount; i++)
                      _ring(cfg, particleT, i),
                    // Particle burst
                    for (int i = 0; i < cfg.particleCount; i++)
                      _particle(i, particleT),
                    // Badge
                    Transform.scale(
                      scale: badgeT.clamp(0.0, 1.4).toDouble(),
                      child: _badge(cfg, imageUrl, t),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _ring(_TierConfig cfg, double t, int index) {
    final delay = index * 0.18;
    final localT = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
    final scale = 0.6 + localT * (widget.event.tier == GiftPopTier.high ? 4.0 : widget.event.tier == GiftPopTier.mid ? 2.6 : 1.6);
    return Opacity(
      opacity: (1 - localT).clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cfg.glow, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _particle(int i, double t) {
    final dx = cos(_angles[i]) * _distances[i] * t;
    final dy = sin(_angles[i]) * _distances[i] * t;
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: (1 - t).clamp(0.0, 1.0),
        child: Container(
          width: _sizes[i],
          height: _sizes[i],
          decoration: BoxDecoration(color: _colors[i], shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _badge(_TierConfig cfg, String? imageUrl, double t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.event.tier == GiftPopTier.high
              ? [const Color(0xFF3A2C0A), const Color(0xFF16161F)]
              : widget.event.tier == GiftPopTier.mid
                  ? [const Color(0xFF1F3318), const Color(0xFF16161F)]
                  : [const Color(0xFF1C2A18), const Color(0xFF16161F)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cfg.glow.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [BoxShadow(color: cfg.glow.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cfg.crown)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Icon(Icons.emoji_events, color: _gold, size: 28),
            ),
          Container(
            width: cfg.badgeSize * 0.55,
            height: cfg.badgeSize * 0.55,
            decoration: BoxDecoration(
              color: cfg.glow.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: cfg.glow.withValues(alpha: 0.4), blurRadius: 24)],
            ),
            child: imageUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => Icon(Icons.card_giftcard, color: Colors.white, size: cfg.badgeSize * 0.28),
                    ),
                  )
                : Icon(Icons.card_giftcard, color: Colors.white, size: cfg.badgeSize * 0.28),
          ),
          if (cfg.label.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              cfg.label,
              style: TextStyle(
                color: cfg.glow,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            [
              if (widget.event.username != null) '${widget.event.username} sent',
              widget.event.giftName,
            ].join(' '),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: cfg.textSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
