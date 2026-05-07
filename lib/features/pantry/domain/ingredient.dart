class Ingredient {
  final String id;
  final String name;
  final String category;
  final String defaultUnit;
  final List<String> searchAliases;
  final String? emoji;
  final bool isStaple;

  /// 'piece' | 'weight' | 'volume'
  ///
  /// Physical measurement type of the ingredient.
  ///
  /// Examples:
  /// - onion: piece
  /// - potatoes: weight
  /// - passata: weight
  /// - milk: volume
  final String measurementType;

  /// 'batch' | 'per_package'
  ///
  /// batch:
  ///   One pantry row represents one added batch.
  ///   Example: 6 eggs, 5 onions, 1000 g potatoes.
  ///
  /// per_package:
  ///   Each added piece/package is stored as a separate pantry row.
  ///   Example: 2 passata packages => 2 rows with amount=1, unit='ks'.
  final String pantryTrackingMode;

  /// Default estimated value per 1 piece/package.
  ///
  /// Examples:
  /// - 1 onion ≈ 120 g
  /// - 1 passata package = 400 g
  /// - 1 milk bottle = 1000 ml
  final double? defaultValuePerPiece;

  /// Unit for [defaultValuePerPiece].
  ///
  /// Typically 'g' or 'ml'.
  final String? defaultValueUnit;

  /// Estimated price in Kč.
  final double? estPrice;

  /// Recommended number of days to use the ingredient within.
  final int? defaultUseWithinDays;

  final double? defaultInputAmount;

  const Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultUnit,
    required this.searchAliases,
    required this.emoji,
    required this.isStaple,
    required this.measurementType,
    required this.pantryTrackingMode,
    required this.defaultValuePerPiece,
    required this.defaultValueUnit,
    required this.estPrice,
    required this.defaultUseWithinDays,
    required this.defaultInputAmount,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      defaultUnit: (json['default_unit'] as String?) ?? 'g',
      searchAliases: List<String>.from(
        (json['search_aliases'] as List<dynamic>?) ?? const [],
      ),
      emoji: json['emoji'] as String?,
      isStaple: (json['is_staple'] as bool?) ?? false,
      measurementType: (json['measurement_type'] as String?) ?? 'piece',
      pantryTrackingMode: (json['pantry_tracking_mode'] as String?) ?? 'batch',
      defaultValuePerPiece:
          (json['default_value_per_piece'] as num?)?.toDouble(),
      defaultValueUnit: json['default_value_unit'] as String?,
      estPrice: (json['est_price'] as num?)?.toDouble(),
      defaultUseWithinDays: (json['default_use_within_days'] as num?)?.toInt(),
      defaultInputAmount: (json['default_input_amount'] as num?)?.toDouble(),
    );
  }

  bool get isPerPackage => pantryTrackingMode == 'per_package';

  bool get isBatch => pantryTrackingMode == 'batch';

  bool get hasDefaultPieceValue {
    final value = defaultValuePerPiece;
    final unit = defaultValueUnit;

    return value != null &&
        value > 0 &&
        unit != null &&
        unit.trim().isNotEmpty;
  }

  /// Unit used in manual add UI and insert payload.
  ///
  /// Important:
  /// - per_package items are always added as 'ks'
  /// - other items use default_unit from the catalog
  ///
  /// Examples:
  /// passata:
  ///   measurementType = weight
  ///   defaultUnit = ks
  ///   pantryTrackingMode = per_package
  ///   derivedUnit = ks
  ///
  /// potatoes:
  ///   measurementType = weight
  ///   defaultUnit = g
  ///   pantryTrackingMode = batch
  ///   derivedUnit = g
  String get derivedUnit {
    if (isPerPackage) return 'ks';
    return defaultUnit;
  }

  /// For now we intentionally display raw units such as 'ks', 'g', 'ml'.
  /// We do not display package-specific labels such as bottle/can/package.
  String get displayAddUnit => derivedUnit;

  String get packageContentLabel {
    if (!hasDefaultPieceValue) return '';

    return '${_formatNumber(defaultValuePerPiece!)} $defaultValueUnit';
  }

  static String _formatNumber(num value) {
    final intValue = value.toInt();

    if (value == intValue) {
      return intValue.toString();
    }

    return value.toStringAsFixed(1);
  }
}