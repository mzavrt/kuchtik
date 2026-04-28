class Ingredient {
  final String id;
  final String name;
  final String category;
  final String defaultUnit;
  final List<String> searchAliases;
  final double? densityGml;
  final String? emoji;
  final bool isStaple;

  Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultUnit,
    required this.searchAliases,
    required this.densityGml,
    required this.emoji,
    required this.isStaple,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String, //UUID
      name: json['name'] as String,
      category: json['category'] as String,
      defaultUnit: json['default_unit'] as String,
      searchAliases: List<String>.from(json['search_aliases'] as List<dynamic>),
      densityGml: (json['density_g_ml'] as num?)?.toDouble(),
      emoji: json['emoji'] as String?,
      isStaple: (json['is_staple'] as bool?) ?? false,
    );
  }
}
