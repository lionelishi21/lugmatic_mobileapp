import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../data/models/gift_model.dart';
import '../../data/providers/auth_provider.dart';

class GiftBottomSheet extends StatefulWidget {
  final String artistId;
  final String artistName;

  const GiftBottomSheet({
    Key? key,
    required this.artistId,
    required this.artistName,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String artistId,
    required String artistName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GiftBottomSheet(artistId: artistId, artistName: artistName),
    );
  }

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet> {
  List<GiftModel> _gifts = [];
  int _coinBalance = 0;
  bool _loading = true;
  String? _sendingId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final apiClient = context.read<ApiClient>();
    try {
      final results = await Future.wait([
        apiClient.dio.get(ApiConfig.gifts),
        apiClient.dio.get(ApiConfig.coinBalance),
      ]);

      final giftsBody = results[0].data;
      final giftsRaw = giftsBody is List ? giftsBody : (giftsBody['data'] ?? []);
      final gifts = (giftsRaw as List)
          .where((g) => g['isActive'] == true)
          .map((j) => GiftModel.fromJson(j as Map<String, dynamic>))
          .toList();

      final balBody = results[1].data;
      final coins = balBody['data']?['coins'] ?? balBody['coins'] ?? 0;

      if (mounted) {
        setState(() {
          _gifts = gifts;
          _coinBalance = coins is int ? coins : (coins as num).toInt();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendGift(GiftModel gift) async {
    final isLoggedIn = context.read<AuthProvider>().isAuthenticated;
    if (!isLoggedIn) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send gifts')),
      );
      return;
    }
    if (_coinBalance < gift.price.toInt()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient coins. Visit the Store to buy more!'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _sendingId = gift.id);
    try {
      final apiClient = context.read<ApiClient>();
      final res = await apiClient.dio.post(
        ApiConfig.sendGift,
        data: {'artistId': widget.artistId, 'giftId': gift.id},
      );
      final body = res.data;
      if (body['success'] == true) {
        if (mounted) {
          setState(() {
            _coinBalance -= gift.price.toInt();
            _sendingId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎁 Gift sent to ${widget.artistName}!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception(body['message'] ?? 'Failed to send gift');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sendingId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A2332),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Send a Gift',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Support ${widget.artistName}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _coinBalance.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2A3545), height: 1),
            // Body
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    )
                  : _gifts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.card_giftcard, color: Colors.white.withOpacity(0.2), size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'No gifts available right now',
                                style: TextStyle(color: Colors.white.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.78,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: _gifts.length,
                          itemBuilder: (context, index) {
                            final gift = _gifts[index];
                            final isSending = _sendingId == gift.id;
                            final canAfford = _coinBalance >= gift.price.toInt();
                            return _GiftCard(
                              gift: gift,
                              isSending: isSending,
                              canAfford: canAfford,
                              onSend: () => _sendGift(gift),
                            );
                          },
                        ),
            ),
            // Footer: Buy Coins
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Need more coins?  ',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/store');
                    },
                    child: const Text(
                      'Visit Store →',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  final GiftModel gift;
  final bool isSending;
  final bool canAfford;
  final VoidCallback onSend;

  const _GiftCard({
    required this.gift,
    required this.isSending,
    required this.canAfford,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConfig.resolveUrl(gift.imageUrl);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.07),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canAfford
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gift image
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: imageUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.card_giftcard,
                        color: Color(0xFF10B981),
                        size: 28,
                      ),
                    ),
                  )
                : const Icon(Icons.card_giftcard, color: Color(0xFF10B981), size: 28),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              gift.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFF10B981), size: 11),
              const SizedBox(width: 3),
              Text(
                '${gift.price.toStringAsFixed(0)} coins',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                gradient: canAfford
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      )
                    : null,
                color: canAfford ? null : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: isSending
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        canAfford ? 'Send' : 'Buy',
                        style: TextStyle(
                          color: canAfford ? Colors.white : Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
