import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lugmatic_flutter/data/services/gift_service.dart';
import 'package:lugmatic_flutter/data/services/stripe_service.dart';
import 'package:lugmatic_flutter/core/theme/neumorphic_theme.dart';
import 'paypal_checkout_page.dart';

enum _PaymentMethod { card, paypal }

class CoinPackage {
  final String label;
  final int amount;
  final String price;
  final String description;
  final IconData icon;
  final Color baseColor;
  final bool popular;

  CoinPackage({
    required this.label,
    required this.amount,
    required this.price,
    required this.description,
    required this.icon,
    required this.baseColor,
    this.popular = false,
  });
}

class StorePage extends StatefulWidget {
  /// Set to true when embedded inside a parent Scaffold (e.g. TabBarView).
  final bool embedded;
  const StorePage({Key? key, this.embedded = false}) : super(key: key);

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  int? _balance;
  bool _isLoadingBalance = true;
  int? _purchasingAmount;
  _PaymentMethod _method = _PaymentMethod.card;

  final List<CoinPackage> _packages = [
    CoinPackage(
      label: 'Starter Pack',
      amount: 500,
      price: '\$5.00',
      description: 'Perfect to try gifting',
      icon: Icons.flash_on,
      baseColor: Colors.blueGrey,
    ),
    CoinPackage(
      label: 'Standard Pack',
      amount: 1000,
      price: '\$10.00',
      description: 'Great value for fans',
      icon: Icons.star,
      baseColor: Colors.blue,
    ),
    CoinPackage(
      label: 'Creator\'s Choice',
      amount: 2000,
      price: '\$20.00',
      description: 'Most popular support',
      icon: Icons.workspace_premium,
      baseColor: const Color(0xFF10B981),
      popular: true,
    ),
    CoinPackage(
      label: 'Super Supporter',
      amount: 5000,
      price: '\$50.00',
      description: 'Show serious support',
      icon: Icons.card_giftcard,
      baseColor: Colors.purple,
    ),
    CoinPackage(
      label: 'Whale Pack',
      amount: 10000,
      price: '\$100.00',
      description: 'Ultimate artist support',
      icon: Icons.shield,
      baseColor: Colors.amber,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    try {
      final giftService = context.read<GiftService>();
      final balanceData = await giftService.getCoinBalance();
      if (mounted) {
        setState(() {
          _balance = balanceData['coins'];
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _handlePurchase(int amount) async {
    setState(() => _purchasingAmount = amount);
    try {
      final stripeService = context.read<StripeService>();
      final error = await stripeService.purchaseCoins(amount);

      if (!mounted) return;

      if (error == null) {
        await _fetchBalance();
        _showDialog(
          icon: Icons.check_circle,
          iconColor: Colors.green,
          title: 'Purchase Complete!',
          message: '$amount coins have been added to your wallet.',
        );
      } else if (error.isNotEmpty) {
        _showDialog(
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
          title: 'Purchase Failed',
          message: error,
        );
      }
    } catch (e) {
      if (mounted) {
        _showDialog(
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
          title: 'Purchase Failed',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasingAmount = null);
    }
  }

  Future<void> _handlePayPalPurchase(int amount) async {
    setState(() => _purchasingAmount = amount);
    try {
      final giftService = context.read<GiftService>();
      final order = await giftService.createPaypalCoinOrder(amount);

      if (order.approveUrl == null) {
        if (mounted) {
          _showDialog(
            icon: Icons.error_outline,
            iconColor: Colors.redAccent,
            title: 'Purchase Failed',
            message: 'Could not start PayPal checkout. Please try again.',
          );
        }
        return;
      }

      if (!mounted) return;
      final approved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PayPalCheckoutPage(approveUrl: order.approveUrl!),
        ),
      );

      if (approved != true) return; // user cancelled — no error dialog needed

      await giftService.capturePaypalOrder(order.orderId);

      if (!mounted) return;
      await _fetchBalance();
      _showDialog(
        icon: Icons.check_circle,
        iconColor: Colors.green,
        title: 'Purchase Complete!',
        message: '$amount coins have been added to your wallet.',
      );
    } catch (e) {
      if (mounted) {
        _showDialog(
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
          title: 'Purchase Failed',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasingAmount = null);
    }
  }

  void _handleBuy(int amount) {
    if (_method == _PaymentMethod.card) {
      _handlePurchase(amount);
    } else {
      _handlePayPalPurchase(amount);
    }
  }

  void _showDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 48),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = CustomScrollView(
      slivers: [
        if (!widget.embedded) _buildAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildBalanceCard(),
                const SizedBox(height: 32),
                _buildMethodPicker(),
                const SizedBox(height: 24),
                const Text(
                  'Select a Package',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPackageCard(_packages[index]),
              ),
              childCount: _packages.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );

    if (widget.embedded) return content;
    return Scaffold(backgroundColor: Colors.black, body: content);
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.black,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Lugmatic Store',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 14),
              SizedBox(width: 6),
              Text(
                'LUGMATIC COINS',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Support Artists',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Buy coins and send gifts directly to your favorite artists. 100% goes to them.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodPicker() {
    Widget option(_PaymentMethod method, IconData icon, String label) {
      final selected = _method == method;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _method = method),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF10B981).withOpacity(0.12) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? const Color(0xFF10B981) : Colors.white.withOpacity(0.08),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? const Color(0xFF10B981) : Colors.white60),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? const Color(0xFF10B981) : Colors.white60,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option(_PaymentMethod.card, Icons.credit_card, 'Card'),
        const SizedBox(width: 12),
        option(_PaymentMethod.paypal, Icons.account_balance_wallet, 'PayPal'),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.15),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.monetization_on,
              size: 100,
              color: const Color(0xFF10B981).withOpacity(0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR BALANCE',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFF10B981), size: 24),
                  const SizedBox(width: 12),
                  if (_isLoadingBalance)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                    )
                  else
                    Text(
                      '${_balance ?? 0}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'coins available',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(CoinPackage package) {
    bool isPurchasing = _purchasingAmount == package.amount;
    
    return Container(
      decoration: BoxDecoration(
        color: package.popular ? const Color(0xFF1A1A1A) : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: package.popular 
            ? const Color(0xFF10B981).withOpacity(0.4) 
            : Colors.white.withOpacity(0.05),
          width: package.popular ? 2 : 1,
        ),
        boxShadow: package.popular 
          ? [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
              )
            ]
          : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: package.baseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(package.icon, color: package.baseColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        package.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (package.popular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${package.amount.toLocaleString()} coins • ${package.price}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: isPurchasing ? null : () => _handleBuy(package.amount),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: package.popular ? const Color(0xFF10B981) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isPurchasing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      'BUY',
                      style: TextStyle(
                        color: package.popular ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension IntFormatting on int {
  String toLocaleString() {
    return toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
