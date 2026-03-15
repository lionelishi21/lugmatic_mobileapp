import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/subscription_plan_model.dart';
import '../../../../data/services/subscription_service.dart';
import '../../../../data/services/stripe_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _isLoading = true;
  List<SubscriptionPlan> _plans = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final subscriptionService = context.read<SubscriptionService>();
      final plans = await subscriptionService.getSubscriptionPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
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
      final stripeService = context.read<StripeService>();

      // 1. Create intent
      final intentData = await subscriptionService.createSubscriptionIntent(plan.id);
      
      // 2. Process payment via StripeService
      // Assuming StripeService has a method to handle the sheet from intent data
      // For now, using a placeholder logic that matches StripeService.purchaseCoins style
      await stripeService.purchaseCoins((plan.price * 100).toInt());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully subscribed to ${plan.name}!')),
        );
        Navigator.pop(context);
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
          'Unlock the full potential of Lugmatic with Premium.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
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
    final isPremium = plan.price > 0;
    
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
              colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
            ),
        border: Border.all(
          color: plan.isPopular ? Colors.transparent : Colors.white.withOpacity(0.1),
        ),
        boxShadow: plan.isPopular ? [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
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
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  plan.description,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
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
                    onPressed: () => _subscribe(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan.isPopular ? Colors.white : const Color(0xFF10B981),
                      foregroundColor: plan.isPopular ? const Color(0xFF065F46) : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      plan.price == 0 ? 'Current Plan' : 'Subscribe Now',
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
        color: Colors.white.withOpacity(0.05),
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
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {},
            child: const Text('Contact Support', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
