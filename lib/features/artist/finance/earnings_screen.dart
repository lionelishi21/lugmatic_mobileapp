import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/neumorphic_theme.dart';
import '../../../data/providers/dashboard_provider.dart';
import '../../../data/models/artist/dashboard_models.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Refresh dashboard data if auth details exist
      final dashboard = context.read<DashboardProvider>();
      if (dashboard.artistDetails?.id != null) {
        dashboard.fetchDashboardData(dashboard.artistDetails!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          final earnings = provider.artistEarnings;
          if (earnings == null) {
            if (!provider.isLoading && provider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                      const SizedBox(height: 12),
                      Text(provider.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedForeground)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _load, child: const Text('Retry', style: TextStyle(color: AppColors.primary))),
                    ],
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(earnings, currency),
                const SizedBox(height: 32),
                const Text('Revenue Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildChartSection(earnings),
                const SizedBox(height: 32),
                const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (earnings.history.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Text('No transaction history yet.', style: TextStyle(color: AppColors.mutedForeground)),
                    ),
                  )
                else
                  ...earnings.history.map((t) => _buildTransactionItem(t, currency)),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildPayoutAction(),
    );
  }

  Widget _buildSummaryCard(ArtistEarnings earnings, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL BALANCE', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(
            currency.format(earnings.totalEarnings),
            style: const TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMiniStat('Monthly', currency.format(earnings.monthlyEarnings)),
              const Spacer(),
              _buildMiniStat('Available', currency.format(earnings.availableBalance)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChartSection(ArtistEarnings earnings) {
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
              spots: _generateSpots(earnings),
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

  /// Cumulative balance over time, derived from real transaction history
  /// (oldest to newest) rather than a hardcoded placeholder series.
  List<FlSpot> _generateSpots(ArtistEarnings earnings) {
    if (earnings.history.isEmpty) return [const FlSpot(0, 0)];
    final chronological = earnings.history.reversed.toList(); // history arrives newest-first
    double running = 0;
    return List.generate(chronological.length, (i) {
      running += chronological[i].amount;
      return FlSpot(i.toDouble(), running);
    });
  }

  Widget _buildTransactionItem(Transaction t, NumberFormat currency) {
    final bool isGift = t.type == 'gift_received';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isGift ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isGift ? FontAwesomeIcons.gift : Icons.music_note, color: isGift ? AppColors.secondary : AppColors.primary, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(DateFormat.yMMMd().format(t.createdAt), style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
              ],
            ),
          ),
          Text(
            currency.format(t.amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            // Show payout request dialog
            _showPayoutDialog();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('REQUEST PAYOUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  void _showPayoutDialog() {
    final availableBalance = context.read<DashboardProvider>().artistEarnings?.availableBalance ?? 0.0;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final canRequest = availableBalance >= 50.0;
    bool isRequesting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Request Payout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(
                  canRequest
                      ? 'Your available balance of ${currency.format(availableBalance)} will be transferred to your linked payout method.'
                      : 'Your available balance is ${currency.format(availableBalance)}. Minimum payout is \$50.00.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.pushNamed(context, '/payout-settings');
                  },
                  icon: const Icon(Icons.settings, color: AppColors.primary, size: 18),
                  label: const Text('Manage Payout Method', style: TextStyle(color: AppColors.primary)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (!canRequest || isRequesting) ? null : () async {
                      setState(() => isRequesting = true);
                      final provider = context.read<DashboardProvider>();
                      // availableBalance is in dollars (see dashboard_models.dart);
                      // the backend expects cents. Using totalEarnings here would
                      // resubmit the artist's full lifetime earnings on every
                      // request, which fails after the first successful payout.
                      final amountCents = availableBalance * 100;
                      final success = await provider.requestPayout(amountCents);

                      if (bottomSheetContext.mounted) {
                        Navigator.pop(bottomSheetContext);
                      }

                      if (this.context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Payout request submitted successfully!'), backgroundColor: AppColors.primary),
                          );
                          // Refresh balance
                          provider.fetchDashboardData(provider.artistDetails?.id ?? '');
                        } else {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(provider.error ?? 'Failed to request payout'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isRequesting
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('CONFIRM PAYOUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}
