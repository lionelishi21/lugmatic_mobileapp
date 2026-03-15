class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String interval;
  final List<String> features;
  final bool isPopular;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.interval,
    required this.features,
    this.isPopular = false,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      interval: json['interval'] ?? 'month',
      features: List<String>.from(json['features'] ?? []),
      isPopular: json['isPopular'] ?? false,
    );
  }
}
