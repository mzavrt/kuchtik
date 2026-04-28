class RecipeDashboardItem {
  RecipeDashboardItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.tags,
    required this.ingredientNames,
    this.prepTimeMinutes,
    this.missingOneText,
  });

  final String id;
  final String title;
  final String imageUrl;
  final List<String> tags;

  /// Ingredient names for local UI filtering.
  ///
  /// Populated by queries that select `recipe_ingredient(ingredients(name))`.
  final List<String> ingredientNames;

  final int? prepTimeMinutes;
  final String? missingOneText;

  RecipeDashboardItem copyWith({
    String? missingOneText,
    int? prepTimeMinutes,
    List<String>? tags,
    List<String>? ingredientNames,
    String? imageUrl,
    String? title,
    String? id,
  }) {
    return RecipeDashboardItem(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      ingredientNames: ingredientNames ?? this.ingredientNames,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      missingOneText: missingOneText ?? this.missingOneText,
    );
  }

  factory RecipeDashboardItem.fromJson(
    Map<String, dynamic> json, {
    String? resolvedImageUrl,
    String? missingOneText,
  }) {
    final recipeIngredients =
        (json['recipe_ingredient'] as List<dynamic>?) ?? const [];

    final names = <String>[];
    for (final ri in recipeIngredients) {
      if (ri is! Map<String, dynamic>) continue;
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
      missingOneText: missingOneText,
      prepTimeMinutes: json['prep_time_minutes'] as int?,
    );
  }
}
