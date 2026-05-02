class RecipeDashboardItem {
  RecipeDashboardItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.tags,
    required this.ingredientNames,
    required this.ingredientIds,
    required this.urgentIngredientCount,
    this.prepTimeMinutes,
    this.missingOneText,
  });

  final String id;
  final String title;
  final String imageUrl;
  final List<String> tags;

  // Ingredient names for local UI filtering.
  final List<String> ingredientNames;

  //Ingredient ids for pantry availability hint.
  final List<String> ingredientIds;

  /// How many of this recipe's ingredients are expiring soon.
  /// Used to sort urgent recipe suggestions.
  final int urgentIngredientCount;

  final int? prepTimeMinutes;
  final String? missingOneText;

  RecipeDashboardItem copyWith({
    String? id,
    String? title,
    String? imageUrl,
    List<String>? tags,
    List<String>? ingredientNames,
    List<String>? ingredientIds,
    int? urgentIngredientCount,
    int? prepTimeMinutes,
    String? missingOneText,
  }) {
    return RecipeDashboardItem(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      ingredientNames: ingredientNames ?? this.ingredientNames,
      ingredientIds: ingredientIds ?? this.ingredientIds,
      urgentIngredientCount: urgentIngredientCount ?? this.urgentIngredientCount,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      missingOneText: missingOneText ?? this.missingOneText,
    );
  }

  factory RecipeDashboardItem.fromJson(
    Map<String, dynamic> json, {
    String? resolvedImageUrl,
    String? missingOneText,
    Set<String> urgentIds = const {},
  }) {
    final recipeIngredients =
        (json['recipe_ingredient'] as List<dynamic>?) ?? const [];

    final names = <String>[];
    final ids = <String>[];
    for (final ri in recipeIngredients) {
      if (ri is! Map<String, dynamic>) continue;

      final ingredientId = (ri['ingredient_id'] as String?)?.trim();
      if (ingredientId != null && ingredientId.isNotEmpty) {
        ids.add(ingredientId);
      }

      final ingredient = ri['ingredients'];
      if (ingredient is Map<String, dynamic>) {
        final n = (ingredient['name'] as String?)?.trim();
        if (n != null && n.isNotEmpty) names.add(n);
      }
    }

    return RecipeDashboardItem(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: resolvedImageUrl ?? (json['image_url'] ?? '') as String,
      tags: List<String>.from((json['tags'] as List<dynamic>? ?? const [])),
      ingredientNames: List<String>.unmodifiable(names),
      ingredientIds: List<String>.unmodifiable(ids),
      urgentIngredientCount: ids.where(urgentIds.contains).length,
      prepTimeMinutes: json['prep_time_minutes'] as int?,
      missingOneText: missingOneText,
    );
  }
}