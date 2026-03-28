import 'package:kuchtik/features/pantry/domain/ingredient.dart';

class UserIngredient {
  final String id; //UUID
  final Ingredient ingredient;
  final double amount;
  final String unit;

  UserIngredient({
    required this.id,
    required this.ingredient,
    required this.amount,
    required this.unit,
  });

  factory UserIngredient.fromJson(Map<String, dynamic> json) {
    return UserIngredient(
      id: json['id'],
      ingredient: Ingredient.fromJson(json['ingredients']), //Table ingredients
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'],
    );
  }

  UserIngredient copyWith({
    String? id,
    Ingredient? ingredient,
    double? amount,
    String? unit,
  }) {
    return UserIngredient(
      id: id ?? this.id,
      ingredient: ingredient ?? this.ingredient,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
    );
  }
}
