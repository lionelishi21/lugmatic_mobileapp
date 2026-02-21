class GiftModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String currency;
  final String category;
  final bool isPopular;
  final bool isLimited;
  final int quantity;
  final String artistId;
  final String artistName;
  final DateTime createdAt;
  final DateTime? expiresAt;

  GiftModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.currency = 'USD',
    required this.category,
    this.isPopular = false,
    this.isLimited = false,
    this.quantity = 1,
    required this.artistId,
    required this.artistName,
    required this.createdAt,
    this.expiresAt,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    return GiftModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image'] ?? json['imageUrl'] ?? '',
      price: (json['coinCost'] ?? json['value'] ?? json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'coins',
      category: json['category'] ?? json['type'] ?? 'support',
      isPopular: json['rarity'] == 'legendary' || json['rarity'] == 'epic' || (json['isPopular'] ?? false),
      isLimited: json['isSeasonal'] ?? json['isLimited'] ?? false,
      quantity: json['quantity'] ?? 1,
      artistId: json['artistId'] ?? '',
      artistName: json['artistName'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      expiresAt: json['seasonalEnd'] != null ? DateTime.tryParse(json['seasonalEnd'].toString()) : json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'currency': currency,
      'category': category,
      'isPopular': isPopular,
      'isLimited': isLimited,
      'quantity': quantity,
      'artistId': artistId,
      'artistName': artistName,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

