class RecipeDashboardItem {
  RecipeDashboardItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.tags,
    required this.urgentIngredientCount,
    required this.availableIngredients,
    required this.totalIngredients,
    this.prepTimeMinutes,
    this.missingOneText,
  });

  final String id;
  final String title;
  final String imageUrl;
  final List<String> tags;
  final int urgentIngredientCount;
  final int availableIngredients;
  final int totalIngredients;
  final int? prepTimeMinutes;
  final String? missingOneText;

  factory RecipeDashboardItem.fromJson(
    Map<String, dynamic> json, {
    String? resolvedImageUrl,
    String? missingOneText,
  }) {
    return RecipeDashboardItem(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: resolvedImageUrl ?? (json['image_url'] as String? ?? ''),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((t) => t?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList(growable: false),
      urgentIngredientCount: json['urgent_ingredient_count'] as int? ?? 0,
      availableIngredients: json['available_ingredients'] as int? ?? 0,
      totalIngredients: json['total_ingredients'] as int? ?? 0,
      prepTimeMinutes: json['prep_time_minutes'] as int?,
      missingOneText: missingOneText ?? json['missing_one_text'] as String?,
    );
  }
}