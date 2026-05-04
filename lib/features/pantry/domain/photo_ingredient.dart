import 'package:kuchtik/features/pantry/domain/ingredient.dart';

class PhotoIngredient {
  final Ingredient ingredient;
  final double amount;
  final String unit;
  final double price;
  final int expiresInDays;
  

  PhotoIngredient({
    required this.ingredient,
    required this.amount,
    required this.unit,
    required this.price,
    required this.expiresInDays,
  
  });

  PhotoIngredient copyWith({
    Ingredient? ingredient,
    double? amount,
    String? unit,
    double? price,
    int? expiresInDays,
  
  }) {
    return PhotoIngredient(
      ingredient: ingredient ?? this.ingredient,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      expiresInDays: expiresInDays ?? this.expiresInDays,
   
    );
  }

  factory PhotoIngredient.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['amount'] ?? json['quantity'];
    final unitRaw = json['unit'] ?? '';
    final priceRaw = json['price'] ?? json['price_czk'] ?? json['price_paid'];
    final expiresRaw = json['expires_in_days'] ?? json['expiresInDays'];

    return PhotoIngredient(
      ingredient: Ingredient.fromJson(
        Map<String, dynamic>.from(
          (json['ingredient'] ?? json['ingredients']) as Map,
        ),
      ),
      amount: (amountRaw as num?)?.toDouble() ?? 0,
      unit: unitRaw is String ? unitRaw : unitRaw.toString(),
      // Can return null if not sure.
      price: (priceRaw as num?)?.toDouble() ?? 0,
      expiresInDays: (expiresRaw as num?)?.toInt() ?? 0,
  
    );
  }
}
