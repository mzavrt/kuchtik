class NotificationData {
  final String id;
  final String name;
  final DateTime? expirationAt;
  final double? price;

  const NotificationData({
    required this.id,
    required this.name,
    required this.expirationAt,
    required this.price,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    final ingredient = json['ingredients'] as Map<String, dynamic>?;

    final pricePaid = json['price_paid'];
    final estPrice = ingredient?['est_price'];

    return NotificationData(
      id: json['id'] as String,
      name: ingredient?['name'] as String? ?? '',
      expirationAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      price: pricePaid != null
          ? (pricePaid as num).toDouble()
          : estPrice == null
              ? null
              : (estPrice as num).toDouble(),
    );
  }
}