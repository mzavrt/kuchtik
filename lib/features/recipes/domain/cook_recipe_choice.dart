class CookRecipeChoice {
  const CookRecipeChoice({
    required this.ingredientId,
    required this.usedAll,
  });

  final String ingredientId;
  final bool usedAll;

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': ingredientId,
      'used_all': usedAll,
    };
  }
}