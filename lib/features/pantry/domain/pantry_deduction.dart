class PantryDeduction {
  final String ingredientId;
  final double amount;
  final String unit;

  const PantryDeduction({
    required this.ingredientId,
    required this.amount,
    required this.unit,
  });

  Map<String, Object?> toJson() => {
        'ingredient_id': ingredientId,
        'amount': amount,
        'unit': unit,
      };
}
