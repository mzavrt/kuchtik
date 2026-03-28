import 'package:kuchtik/models/ingredient.dart';

class PhotoIngredient {
 
  final Ingredient ingredient;
  final double amount;
  final String unit;

  PhotoIngredient({
    required this.ingredient,
    required this.amount,
    required this.unit,
  });

  factory PhotoIngredient.fromJson(Map<String, dynamic> json) {
    return PhotoIngredient(
      ingredient: Ingredient.fromJson(json['ingredient']), //Table ingredients
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'],
    );
  }
}