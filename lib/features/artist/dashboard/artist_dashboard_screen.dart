import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/track_provider.dart';
import '../../../data/providers/section_provider.dart';
import '../../../data/providers/dashboard_provider.dart';
import '../../../data/models/artist/dashboard_models.dart';
import 'track_analytics_screen.dart';

class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});
  @override
  State<ArtistDashboardScreen> createState() => _ArtistDashboardScreenState();
}

class _ArtistDashboardScreenState extends State<ArtistDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final artistId = auth.user?.artistId ?? auth.user?.id;
      if (artistId != null) {
        context.read<DashboardProvider>().fetchDashboardData(artistId);
        context.read<TrackProvider>().fetchTracks(artistId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer3<AuthProvider, DashboardProvider, TrackProvider>(
        builder: (context, auth, dashboard, trackProvider, _) {
          final sectionProvider = context.read<SectionProvider>();
          final artistName = dashboard.artistDetails?.name ?? auth.user?.fullName ?? 'Artist';
          final profileUrl = dashboard.artistDetails?.profilePicture ?? dashboard.artistDetails?.image ?? auth.user?.profilePicture;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.background,
                pinned: true,
                elevation: 0,
                toolbarHeight: 70,
                automaticallyImplyLeading: false,
                flexibleSpace: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => sectionProvider.setArtistTab(5),
                          child: Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2),
                              image: profileUrl != null
                                  ? DecorationImage(image: NetworkImage(profileUrl), fit: BoxFit.cover)
                                  : null,
                              color: AppColors.card,
                            ),
                            child: profileUrl == null
                                ? const Icon(Icons.person, color: AppColors.primary, size: 22)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Dashboard',
                                      style: TextStyle(color: AppColors.foreground, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                                  Text('Welcome back, $artistName',
                                      style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                                ],
                              ),
                              GestureDetector(
                                onTap: () { sectionProvider.switchTo(AppSection.fan); Navigator.of(context).pop(); },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.headphones, size: 14, color: AppColors.mutedForeground),
                                    SizedBox(width: 4),
                                    Text('Fan Mode', style: TextStyle(color: AppColors.mutedForeground, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _GoLiveBanner(onTap: () => sectionProvider.setArtistTab(2)),
                    const SizedBox(height: 14),
                    if (!dashboard.isLoading)
                      _StatsRow(stats: dashboard.artistStats, earnings: dashboard.artistEarnings, onTracksTap: () => sectionProvider.setArtistTab(1)),
                    if (dashboard.isLoading)
                      const SizedBox(height: 90, child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))),
                    const SizedBox(height: 28),
                    const _SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 14),
                    _QuickActions(sectionProvider: sectionProvider),
                    const SizedBox(height: 28),
                    _SectionHeader(title: 'My Tracks', action: 'See All', onAction: () => sectionProvider.setArtistTab(1)),
                    const SizedBox(height: 14),
                    if (trackProvider.isLoading)
                      const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
                    else if (trackProvider.tracks.isEmpty)
                      const _EmptyState(icon: FontAwesomeIcons.music, message: 'No tracks yet — upload your first one!')
                    else
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: trackProvider.tracks.length > 6 ? 6 : trackProvider.tracks.length,
                          itemBuilder: (_, i) => _TrackCard(track: trackProvider.tracks[i]),
                        ),
                      ),
                    const SizedBox(height: 28),
                    const _SectionHeader(title: 'Recent Activity'),
                    const SizedBox(height: 14),
                    if (dashboard.artistEarnings?.history.isNotEmpty == true)
                      ...dashboard.artistEarnings!.history.take(5).map((t) => _ActivityItem(transaction: t))
                    else
                      const _EmptyState(icon: FontAwesomeIcons.clockRotateLeft, message: 'No recent activity yet.'),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoLiveBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _GoLiveBanner({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A2E14), Color(0xFF0D1A0A)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withValues(alpha: 0.4))),
          child: const Icon(FontAwesomeIcons.towerBroadcast, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 16),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Go Live Now', style: TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 3),
          Text('Stream to your fans in real-time', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
          child: const Text('Start', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ]),
    ),
  );
}

class _StatsRow extends StatelessWidget {
  final ArtistStats? stats;
  final ArtistEarnings? earnings;
  final VoidCallback onTracksTap;
  const _StatsRow({this.stats, this.earnings, required this.onTracksTap});

  @override
  Widget build(BuildContext context) {
    final compact = NumberFormat.compact();
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final items = [
      _StatData('Plays', stats != null ? compact.format(stats!.totalPlays) : '0', FontAwesomeIcons.play, AppColors.primary),
      _StatData('Listeners', stats != null ? compact.format(stats!.monthlyListeners) : '0', FontAwesomeIcons.headphones, const Color(0xFF7B6FFF)),
      _StatData('Followers', stats != null ? compact.format(stats!.socialMediaFollowers) : '0', FontAwesomeIcons.users, const Color(0xFF4CBBFF)),
      _StatData('Earned', earnings != null ? currency.format(earnings!.totalEarnings) : '\$0', FontAwesomeIcons.coins, const Color(0xFFFFB347)),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Row(children: items.map((d) => Expanded(child: _StatCell(data: d))).toList()),
    );
  }
}

class _StatData { final String label, value; final IconData icon; final Color color; const _StatData(this.label, this.value, this.icon, this.color); }
class _StatCell extends StatelessWidget {
  final _StatData data; const _StatCell({required this.data});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: data.color.withValues(alpha: 0.1), shape: BoxShape.circle), child: FaIcon(data.icon, size: 14, color: data.color)),
    const SizedBox(height: 6),
    Text(data.value, style: const TextStyle(color: AppColors.foreground, fontSize: 15, fontWeight: FontWeight.bold)),
    const SizedBox(height: 2),
    Text(data.label, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 10)),
  ]);
}

class _QuickActions extends StatelessWidget {
  final SectionProvider sectionProvider;
  const _QuickActions({required this.sectionProvider});
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction('Clash', FontAwesomeIcons.fire, const Color(0xFFFF6B6B), () => sectionProvider.setArtistTab(3)),
      _QuickAction('Tracks', FontAwesomeIcons.music, AppColors.primary, () => sectionProvider.setArtistTab(1)),
      _QuickAction('Upload', FontAwesomeIcons.cloudArrowUp, const Color(0xFF7B6FFF), () => Navigator.of(context).pushNamed('/artist/upload')),
      _QuickAction('Earnings', FontAwesomeIcons.coins, const Color(0xFFFFB347), () => Navigator.of(context).pushNamed('/artist/earnings')),
    ];
    return Row(children: List.generate(actions.length, (i) {
      final a = actions[i];
      return Expanded(child: GestureDetector(
        onTap: a.onTap,
        child: Container(
          margin: EdgeInsets.only(right: i < actions.length - 1 ? 10 : 0),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: a.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: a.color.withValues(alpha: 0.18))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FaIcon(a.icon, size: 18, color: a.color),
            const SizedBox(height: 6),
            Text(a.label, style: TextStyle(color: a.color, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
      ));
    }));
  }
}

class _QuickAction { final String label; final IconData icon; final Color color; final VoidCallback onTap; const _QuickAction(this.label, this.icon, this.color, this.onTap); }

class _SectionHeader extends StatelessWidget {
  final String title; final String? action; final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(title, style: const TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold)),
    if (action != null) GestureDetector(onTap: onAction, child: Text(action!, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600))),
  ]);
}

class _TrackCard extends StatelessWidget {
  final dynamic track; const _TrackCard({required this.track});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackAnalyticsScreen(track: track))),
    child: Container(
      width: MediaQuery.of(context).size.width * 0.32,
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 160),
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: track.coverArtUrl != null || track.coverArt != null
              ? Image.network(track.coverArtUrl ?? track.coverArt!, height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
              : _placeholder(),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(track.name, style: const TextStyle(color: AppColors.foreground, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            const FaIcon(FontAwesomeIcons.play, size: 8, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(NumberFormat.compact().format(track.playCount ?? 0), style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
        ])),
      ]),
    ),
  );
  Widget _placeholder() => Container(height: 100, width: double.infinity, color: AppColors.muted, child: const Center(child: FaIcon(FontAwesomeIcons.music, color: AppColors.primary, size: 18)));
}

class _ActivityItem extends StatelessWidget {
  final Transaction transaction; const _ActivityItem({required this.transaction});
  @override
  Widget build(BuildContext context) {
    final IconData icon; final Color color;
    if (transaction.type == 'gift_received') { icon = FontAwesomeIcons.gift; color = AppColors.secondary; }
    else if (transaction.type == 'payout') { icon = FontAwesomeIcons.wallet; color = Colors.orangeAccent; }
    else { icon = FontAwesomeIcons.moneyBillTransfer; color = AppColors.primary; }
    final isPositive = transaction.amount >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: FaIcon(icon, color: color, size: 16)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(transaction.description, style: const TextStyle(color: AppColors.foreground, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(DateFormat.yMMMd().format(transaction.createdAt), style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
        ])),
        Text('${isPositive ? '+' : ''}\$${transaction.amount.abs().toStringAsFixed(2)}',
            style: TextStyle(color: isPositive ? AppColors.primary : AppColors.error, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
    child: Row(children: [
      FaIcon(icon, color: AppColors.mutedForeground, size: 18),
      const SizedBox(width: 14),
      Expanded(child: Text(message, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13))),
    ]),
  );
}
