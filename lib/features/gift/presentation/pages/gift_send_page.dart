import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/data/models/gift_model.dart';
import 'package:lugmatic_flutter/data/models/artist_model.dart';

class GiftSendPage extends StatefulWidget {
  final ArtistModel? selectedArtist;
  
  const GiftSendPage({Key? key, this.selectedArtist}) : super(key: key);

  @override
  State<GiftSendPage> createState() => _GiftSendPageState();
}

class _GiftSendPageState extends State<GiftSendPage> {
  ArtistModel? _selectedArtist;
  GiftModel? _selectedGift;
  String _message = '';
  final TextEditingController _messageController = TextEditingController();

  final List<GiftModel> _popularGifts = [
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
  ];

  final List<ArtistModel> _recentArtists = [
    ArtistModel(
      id: '1',
      name: 'Luna Nova',
      imageUrl: 'https://via.placeholder.com/300x300/10B981/FFFFFF?text=Luna',
      bio: 'Electronic music producer and DJ',
      followers: 125000,
      isVerified: true,
      genres: ['Electronic', 'Ambient'],
      location: 'Los Angeles, CA',
    ),
    ArtistModel(
      id: '2',
      name: 'Thunder Band',
      imageUrl: 'https://via.placeholder.com/300x300/EF4444/FFFFFF?text=Thunder',
      bio: 'Rock band with electrifying performances',
      followers: 89000,
      isVerified: true,
      genres: ['Rock', 'Alternative'],
      location: 'Seattle, WA',
    ),
    ArtistModel(
      id: '3',
      name: 'Chill Wave',
      imageUrl: 'https://via.placeholder.com/300x300/06B6D4/FFFFFF?text=Chill',
      bio: 'Ambient and chill music creator',
      followers: 67000,
      isVerified: false,
      genres: ['Ambient', 'Chill'],
      location: 'Portland, OR',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedArtist = widget.selectedArtist;
  }

  @override
  void dispose() {
    _messageController.dispose();
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
                _buildArtistSelection(),
                const SizedBox(height: 24),
                _buildSelectedGift(),
                const SizedBox(height: 24),
                _buildSectionHeader('Popular Gifts'),
                const SizedBox(height: 16),
                _buildGiftsGrid(),
                const SizedBox(height: 32),
                _buildSectionHeader('Recent Artists'),
                const SizedBox(height: 16),
                _buildRecentArtists(),
                const SizedBox(height: 32),
                _buildMessageSection(),
                const SizedBox(height: 32),
                _buildSendButton(),
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
        'Send Gift',
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

  Widget _buildArtistSelection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFFFFD700).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send Gift To',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedArtist != null)
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    image: DecorationImage(
                      image: NetworkImage(_selectedArtist!.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _selectedArtist!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedArtist!.isVerified)
                            const SizedBox(width: 8),
                          if (_selectedArtist!.isVerified)
                            const Icon(
                              Icons.verified,
                              color: Color(0xFFFFD700),
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedArtist!.genres.isNotEmpty ? _selectedArtist!.genres.first : 'Artist',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showArtistSelectionDialog(),
                  icon: const Icon(Icons.edit, color: Color(0xFFFFD700)),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showArtistSelectionDialog(),
                icon: const Icon(Icons.person_add, size: 20),
                label: const Text('Select Artist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedGift() {
    if (_selectedGift == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(_selectedGift!.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedGift!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedGift!.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '\$${_selectedGift!.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_selectedGift!.isLimited)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'LIMITED',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedGift = null),
            icon: const Icon(Icons.close, color: Colors.white),
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
        itemCount: _popularGifts.length,
        itemBuilder: (context, index) {
          final gift = _popularGifts[index];
          return _buildGiftCard(gift);
        },
      ),
    );
  }

  Widget _buildGiftCard(GiftModel gift) {
    final isSelected = _selectedGift?.id == gift.id;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isSelected 
            ? const Color(0xFFFFD700).withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        border: Border.all(
          color: isSelected 
              ? const Color(0xFFFFD700)
              : Colors.white.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedGift = gift),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(gift.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  gift.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${gift.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentArtists() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recentArtists.length,
        itemBuilder: (context, index) {
          final artist = _recentArtists[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: _buildArtistCard(artist),
          );
        },
      ),
    );
  }

  Widget _buildArtistCard(ArtistModel artist) {
    return GestureDetector(
      onTap: () => setState(() => _selectedArtist = artist),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedArtist?.id == artist.id 
                ? const Color(0xFFFFD700)
                : Colors.white.withOpacity(0.1),
            width: _selectedArtist?.id == artist.id ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                image: DecorationImage(
                  image: NetworkImage(artist.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              artist.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Message (Optional)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a personal message with your gift...',
              hintStyle: TextStyle(color: Colors.white60),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) => setState(() => _message = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = _selectedArtist != null && _selectedGift != null;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canSend ? _sendGift : null,
        icon: const Icon(Icons.card_giftcard, size: 20),
        label: Text(
          canSend 
              ? 'Send Gift (\$${_selectedGift!.price.toStringAsFixed(2)})'
              : 'Select Artist & Gift',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canSend ? const Color(0xFFFFD700) : Colors.grey,
          foregroundColor: canSend ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showArtistSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Select Artist',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _recentArtists.length,
            itemBuilder: (context, index) {
              final artist = _recentArtists[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(artist.imageUrl),
                ),
                title: Text(
                  artist.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  artist.genres.isNotEmpty ? artist.genres.first : 'Artist',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: artist.isVerified 
                    ? const Icon(Icons.verified, color: Color(0xFFFFD700))
                    : null,
                onTap: () {
                  setState(() => _selectedArtist = artist);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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

  void _sendGift() {
    if (_selectedArtist == null || _selectedGift == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Confirm Gift',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send ${_selectedGift!.name} to ${_selectedArtist!.name}?',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Cost: \$${_selectedGift!.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Message:',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                _message,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processGiftSending();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _processGiftSending() {
    // Show success animation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Gift sent to ${_selectedArtist!.name}! 🎁',
        ),
        backgroundColor: const Color(0xFFFFD700),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Reset selections
    setState(() {
      _selectedGift = null;
      _message = '';
      _messageController.clear();
    });
  }
}
