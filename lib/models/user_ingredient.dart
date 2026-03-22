
import 'package:kuchtik/models/ingredient.dart';

class UserIngredient {
  final String id; //UUID
  final Ingredient ingredient;
  final int amount;
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
      amount: json['amount'],
      unit: json['unit'],
    );
  }
}