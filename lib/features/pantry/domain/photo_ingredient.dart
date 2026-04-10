import 'package:kuchtik/features/pantry/domain/ingredient.dart';

class PhotoIngredient {
  final Ingredient ingredient;
  final double amount;
  final String unit;
  final double price;
  final int expiresInDays;
  final bool isDiscounted;

  PhotoIngredient({
    required this.ingredient,
    required this.amount,
    required this.unit,
    required this.price,
    required this.expiresInDays,
    required this.isDiscounted,
  });

  factory PhotoIngredient.fromJson(Map<String, dynamic> json) {
    return PhotoIngredient(
      ingredient: Ingredient.fromJson(json['ingredient']), //Table ingredients
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'],
      price: (json['price'] as num).toDouble(),
      expiresInDays: json['expires_in_days'] as int,
      isDiscounted: json['is_discounted'] as bool,
    );
  }
}
