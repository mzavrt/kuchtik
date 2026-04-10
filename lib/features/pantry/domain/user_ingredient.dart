import 'package:kuchtik/features/pantry/domain/ingredient.dart';

class UserIngredient {
  final String id; //UUID
  final Ingredient ingredient;
  final double amount;
  final String unit;
  final double price;
  final DateTime expiresAt; 
  final bool isDiscounted;

  UserIngredient({
    required this.id,
    required this.ingredient,
    required this.amount,
    required this.unit,
    required this.price,
    required this.expiresAt,
    required this.isDiscounted,
  });

  factory UserIngredient.fromJson(Map<String, dynamic> json) {
    return UserIngredient(
      id: json['id'],
      ingredient: Ingredient.fromJson(json['ingredients']), //Table ingredients
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'],
      price: ((json['price_paid'] as num?) ?? 0).toDouble(),
      expiresAt: json['expires_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['expires_at'] as String),
      isDiscounted: (json['is_discounted'] as bool?) ?? false,
    );
  }

  UserIngredient copyWith({
    String? id,
    Ingredient? ingredient,
    double? amount,
    String? unit,
    double? price,
    DateTime? expiresAt,
    bool? isDiscounted,
  }) {
    return UserIngredient(
      id: id ?? this.id,
      ingredient: ingredient ?? this.ingredient,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      expiresAt: expiresAt ?? this.expiresAt,
      isDiscounted: isDiscounted ?? this.isDiscounted,
    );
  }
}
