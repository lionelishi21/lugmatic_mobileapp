import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/neumorphic_theme.dart';
import '../../../data/models/artist/track_model.dart';
import '../../../data/providers/track_provider.dart';

class TrackAnalyticsScreen extends StatefulWidget {
  final Track track;
  const TrackAnalyticsScreen({super.key, required this.track});

  @override
  State<TrackAnalyticsScreen> createState() => _TrackAnalyticsScreenState();
}

class _TrackAnalyticsScreenState extends State<TrackAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackProvider>().fetchTrackAnalytics(widget.track.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.track.name, style: const TextStyle(color: AppColors.foreground)),
        iconTheme: const IconThemeData(color: AppColors.foreground),
      ),
      body: Consumer<TrackProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.mutedForeground, size: 40),
                  const SizedBox(height: 12),
                  Text(provider.error!, style: const TextStyle(color: AppColors.mutedForeground), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.read<TrackProvider>().fetchTrackAnalytics(widget.track.id),
                    child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            );
          }

          final analytics = provider.selectedTrackAnalytics;
          if (analytics == null) {
            return const Center(
              child: Text('No analytics yet', style: TextStyle(color: AppColors.mutedForeground)),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<TrackProvider>().fetchTrackAnalytics(widget.track.id),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildTotalsCard(analytics),
                const SizedBox(height: 20),
                _buildChartCard(analytics),
                const SizedBox(height: 20),
                _buildDeviceBreakdown(analytics),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalsCard(TrackAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL PLAYS', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('${analytics.totalPlays}', style: const TextStyle(color: AppColors.foreground, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Last ${analytics.period} days', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChartCard(TrackAnalytics analytics) {
    if (analytics.dailyStats.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(20)),
        child: const Text('No plays in this period', style: TextStyle(color: AppColors.mutedForeground)),
      );
    }
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(20)),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                analytics.dailyStats.length,
                (i) => FlSpot(i.toDouble(), analytics.dailyStats[i].plays.toDouble()),
              ),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceBreakdown(TrackAnalytics analytics) {
    if (analytics.deviceStats.isEmpty) {
      return const SizedBox.shrink();
    }
    final total = analytics.deviceStats.fold<int>(0, (sum, d) => sum + d.count);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DEVICE BREAKDOWN', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          ...analytics.deviceStats.map((d) {
            final pct = total == 0 ? 0.0 : d.count / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(d.device, style: const TextStyle(color: AppColors.foreground, fontSize: 13))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${d.count}', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
