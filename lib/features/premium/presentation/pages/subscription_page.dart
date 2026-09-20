import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/subscription_plan_model.dart';
import '../../../../data/services/subscription_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _isLoading = true;
  List<SubscriptionPlan> _plans = [];
  String? _error;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final subscriptionService = context.read<SubscriptionService>();
      final results = await Future.wait([
        subscriptionService.getSubscriptionPlans(),
        subscriptionService.isPremium(),
      ]);
      if (mounted) {
        setState(() {
          _plans = results[0] as List<SubscriptionPlan>;
          _isPremium = results[1] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    if (plan.price == 0) {
      // Handle free tier selection if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Free tier selected.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final subscriptionService = context.read<SubscriptionService>();

      // 1. Purchase via RevenueCat
      final customerInfo = await subscriptionService.purchaseSubscription(plan);
      
      if (customerInfo != null && customerInfo.entitlements.active.isNotEmpty) {
        if (mounted) {
          setState(() => _isPremium = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully subscribed to ${plan.name}!')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase cancelled or failed.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _manageSubscription() async {
    final subscriptionService = context.read<SubscriptionService>();
    final url = await subscriptionService.getManagementUrl();
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manage your subscription from your device\'s App Store / Play Store settings.')),
      );
    }
  }

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@lugmaticmusic.com',
      query: 'subject=Subscription support',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email us at support@lugmaticmusic.com')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                  else if (_error != null)
                    _buildErrorWidget()
                  else
                    _buildPlansList(),
                  const SizedBox(height: 40),
                  _buildSupportSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      pinned: true,
      expandedHeight: 0,
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Plan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unlock the full potential of Lumatix with Premium.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPlansList() {
    return Column(
      children: _plans.map((plan) => _buildPlanCard(plan)).toList(),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isFreePlan = plan.price == 0;
    final isCurrentPaidPlan = _isPremium && !isFreePlan;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: plan.isPopular 
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10B981), Color(0xFF065F46)],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
            ),
        border: Border.all(
          color: plan.isPopular ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: plan.isPopular ? [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ] : [],
      ),
      child: Column(
        children: [
          if (plan.isPopular)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$${plan.price.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '/${plan.interval == 'month' ? 'mo' : 'yr'}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  plan.description,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
                const Divider(height: 40, color: Colors.white24),
                ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: plan.isPopular ? Colors.white : const Color(0xFF10B981), size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isFreePlan
                        ? null
                        : isCurrentPaidPlan
                            ? _manageSubscription
                            : _isPremium
                                ? null // already on a different paid plan — manage/switch via the store instead
                                : () => _subscribe(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan.isPopular ? Colors.white : const Color(0xFF10B981),
                      foregroundColor: plan.isPopular ? const Color(0xFF065F46) : Colors.white,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isFreePlan
                          ? 'Current Plan'
                          : isCurrentPaidPlan
                              ? 'Manage Subscription'
                              : _isPremium
                                  ? 'Switch via App Store'
                                  : 'Subscribe Now',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.white70)),
          TextButton(onPressed: _loadPlans, child: const Text('Retry', style: TextStyle(color: Color(0xFF10B981)))),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.headset_mic_outlined, color: Color(0xFF10B981), size: 32),
          const SizedBox(height: 16),
          const Text(
            'Need assistance?',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Our support team is here to help you with any questions about your subscription.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _contactSupport,
            child: const Text('Contact Support', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
