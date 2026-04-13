class RecipeIngredient {
  final String ingredientId;
  final String name;
  final num? amount;
  final String? unit;
  final double? densityGml;

  RecipeIngredient({
    required this.ingredientId,
    required this.name,
    required this.amount,
    required this.unit,
    required this.densityGml,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    
    final ingredientData = json['ingredients'] as Map<String, dynamic>?;

    return RecipeIngredient(
      ingredientId: ingredientData?['id'] as String? ?? '',
      name: ingredientData?['name'] as String? ?? 'Unknown Ingredient',
      amount: json['amount'] as num?,
      unit: json['unit'] as String?,
      densityGml: (ingredientData?['density_g_ml'] as num?)?.toDouble(),
    );
  }
}




