class Ingredient {
  final String id;
  final String name;
  final String category;
  final String defaultUnit;
  final List<String> searchAliases;
  final String? emoji;
  final bool isStaple;

  /// 'piece' | 'weight' | 'volume'
  final String measurementType;

  /// Estimated value per 1 unit (in [estUnit]).
  final double? estValue;

  /// 'g'|'ml' for weight/volume types, null for piece.
  final String? estUnit;

  /// Estimated price (Kč)
  final double? estPrice;

  final int? defaultUseWithinDays;

  Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultUnit,
    required this.searchAliases,
    required this.emoji,
    required this.isStaple,
    required this.measurementType,
    required this.estValue,
    required this.estUnit,
    required this.estPrice,
    required this.defaultUseWithinDays,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String, //UUID
      name: json['name'] as String,
      category: json['category'] as String,
      defaultUnit: json['default_unit'] as String,
      searchAliases: List<String>.from(json['search_aliases'] as List<dynamic>),
      emoji: json['emoji'] as String?,
      isStaple: (json['is_staple'] as bool?) ?? false,

      measurementType: (json['measurement_type'] as String?) ?? 'piece',
      estValue: (json['est_value'] as num?)?.toDouble(),
      estUnit: json['est_unit'] as String?,
      estPrice: (json['est_price'] as num?)?.toDouble(),
      defaultUseWithinDays: json['default_use_within_days'] as int?,
    );
  }


String get derivedUnit => switch (measurementType.trim()) {
  'weight' => estUnit ?? 'g',
  'volume' => estUnit ?? 'ml',
  _ => 'ks',
};
}
