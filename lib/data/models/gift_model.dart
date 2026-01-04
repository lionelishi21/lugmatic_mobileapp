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
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      price: (json['price'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      category: json['category'],
      isPopular: json['isPopular'] ?? false,
      isLimited: json['isLimited'] ?? false,
      quantity: json['quantity'] ?? 1,
      artistId: json['artistId'],
      artistName: json['artistName'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
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

