import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/gift_model.dart';

class GiftDiscoverPage extends StatefulWidget {
  const GiftDiscoverPage({Key? key}) : super(key: key);

  @override
  State<GiftDiscoverPage> createState() => _GiftDiscoverPageState();
}

class _GiftDiscoverPageState extends State<GiftDiscoverPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All', 'Flowers', 'Premium', 'Emotions', 'Music', 'Special', 'Limited'
  ];

  final List<GiftModel> _allGifts = [
    GiftModel(
      id: '1',
      name: 'Virtual Rose',
      description: 'Send a beautiful virtual rose to show your appreciation',
      imageUrl: 'https://via.placeholder.com/300x300/FF69B4/FFFFFF?text=Rose',
      price: 2.99,
      category: 'Flowers',
      isPopular: true,
      artistId: '',
      artistName: '',
      createdAt: DateTime.now(),
    ),
    GiftModel(
      id: '2',
      name: 'Golden Crown',
      description: 'Crown your favorite artist with this golden gift',
      imageUrl: 'https://via.placeholder.com/300x300/FFD700/FFFFFF?text=Crown',
      price: 9.99,
      category: 'Premium',
      isPopular: true,
      isLimited: true,
      artistId: '',
      artistName: '',
      createdAt: DateTime.now(),
    ),
    GiftModel(
      id: '3',
      name: 'Heart Emoji',
      description: 'Simple and sweet way to show love',
      imageUrl: 'https://via.placeholder.com/300x300/FF6B6B/FFFFFF?text=Heart',
      price: 1.99,
      category: 'Emotions',
      artistId: '',
      artistName: '',
      createdAt: DateTime.now(),
    ),
    GiftModel(
      id: '4',
      name: 'Diamond Ring',
      description: 'Sparkling diamond to show your devotion',
      imageUrl: 'https://via.placeholder.com/300x300/B0E0E6/FFFFFF?text=Diamond',
      price: 19.99,
      category: 'Premium',
      isLimited: true,
      artistId: '',
      artistName: '',
      createdAt: DateTime.now(),
    ),
    GiftModel(
      id: '5',
      name: 'Musical Note',
      description: 'Perfect gift for music lovers',
      imageUrl: 'https://via.placeholder.com/300x300/9370DB/FFFFFF?text=Music',
      price: 3.99,
      category: 'Music',
      artistId: '',
      artistName: '',
      createdAt: DateTime.now(),
    ),
    GiftModel(
      id: '6',
      name: 'Star',
      description: 'Make them feel like a star',
      imageUrl: 'https://via.placeholder.com/300x300/FFA500/FFFFFF?text=Star',
      price: 4.99,
      category: 'Premium',
      artistId: '',
      artistName: '',
      createdAt: DateTime.now(),
    ),
    GiftModel(
      id: '7',
      name: 'Rainbow',
      description: 'Colorful rainbow to brighten their day',
      imageUrl: 'https://via.placeholder.com/300x300/FF69B4/FFFFFF?text=Rainbow',
      price: 5.99,
      category: 'Special',
      artistId: '',
      artistName: '',
      createdAt: DateTime.now(),
    ),
    GiftModel(
      id: '8',
      name: 'Trophy',
      description: 'Celebrate their achievements',
      imageUrl: 'https://via.placeholder.com/300x300/FFD700/FFFFFF?text=Trophy',
      price: 12.99,
      category: 'Premium',
      isLimited: true,
      artistId: '',
      artistName: '',
      createdAt: DateTime.now(),
    ),
    GiftModel(
      id: '9',
      name: 'Smile',
      description: 'Spread joy with a bright smile',
      imageUrl: 'https://via.placeholder.com/300x300/FFD700/FFFFFF?text=Smile',
      price: 0.99,
      category: 'Emotions',
      artistId: '',
      artistName: '',
      createdAt: DateTime.now(),
    ),
  ];

  final List<Map<String, dynamic>> _topGifters = [
    {
      'name': 'MusicLover123',
      'totalSpent': 250.0,
      'giftsSent': 45,
      'avatar': 'https://via.placeholder.com/300x300/10B981/FFFFFF?text=ML',
    },
    {
      'name': 'SuperFan2024',
      'totalSpent': 180.0,
      'giftsSent': 32,
      'avatar': 'https://via.placeholder.com/300x300/8B5CF6/FFFFFF?text=SF',
    },
    {
      'name': 'ArtistSupporter',
      'totalSpent': 150.0,
      'giftsSent': 28,
      'avatar': 'https://via.placeholder.com/300x300/F59E0B/FFFFFF?text=AS',
    },
  ];

  List<GiftModel> get _filteredGifts {
    if (_selectedCategory == 'All') {
      return _allGifts;
    }
    return _allGifts.where((gift) => gift.category == _selectedCategory).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 24),
                _buildCategoriesFilter(),
                const SizedBox(height: 24),
                _buildSectionHeader('Popular Gifts'),
                const SizedBox(height: 16),
                _buildPopularGifts(),
                const SizedBox(height: 32),
                _buildSectionHeader('All Gifts'),
                const SizedBox(height: 16),
                _buildGiftsGrid(),
                const SizedBox(height: 32),
                _buildSectionHeader('Top Gifters'),
                const SizedBox(height: 16),
                _buildTopGifters(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: const Color(0xFF111827),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Gift Store',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
          onPressed: () => _showWalletDialog(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search gifts...',
          hintStyle: TextStyle(color: Colors.white60),
          prefixIcon: Icon(Icons.search, color: Colors.white60),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          // Handle search
        },
      ),
    );
  }

  Widget _buildCategoriesFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.white.withOpacity(0.1),
                    selectedColor: const Color(0xFFFFD700),
                    checkmarkColor: Colors.black,
                    side: BorderSide(
                      color: isSelected 
                          ? const Color(0xFFFFD700)
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPopularGifts() {
    final popularGifts = _allGifts.where((gift) => gift.isPopular).toList();
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: popularGifts.length,
        itemBuilder: (context, index) {
          final gift = popularGifts[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: _buildGiftCard(gift, isPopular: true),
          );
        },
      ),
    );
  }

  Widget _buildGiftsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: _filteredGifts.length,
        itemBuilder: (context, index) {
          final gift = _filteredGifts[index];
          return _buildGiftCard(gift);
        },
      ),
    );
  }

  Widget _buildGiftCard(GiftModel gift, {bool isPopular = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: isPopular 
              ? const Color(0xFFFFD700).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showGiftDetails(gift),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: isPopular ? 100 : 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(gift.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (gift.isLimited)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: const Text(
                            'LIMITED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (isPopular)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD700),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  gift.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isPopular ? 14 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${gift.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: const Color(0xFFFFD700),
                    fontSize: isPopular ? 16 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isPopular) ...[
                  const SizedBox(height: 4),
                  Text(
                    gift.category,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopGifters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _topGifters.map((gifter) => _buildGifterCard(gifter)).toList(),
      ),
    );
  }

  Widget _buildGifterCard(Map<String, dynamic> gifter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(gifter['avatar']),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gifter['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${gifter['giftsSent']} gifts sent',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${gifter['totalSpent'].toStringAsFixed(0)} total spent',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'VIP',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGiftDetails(GiftModel gift) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: Text(
          gift.name,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(gift.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              gift.description,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category: ${gift.category}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  '\$${gift.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (gift.isLimited) ...[
              const SizedBox(height: 8),
              const Text(
                '⚠️ Limited Edition',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to send gift page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Send Gift'),
          ),
        ],
      ),
    );
  }

  void _showWalletDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Wallet',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Current Balance',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              '\$25.50',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => print('Add funds'),
              icon: const Icon(Icons.add),
              label: const Text('Add Funds'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
