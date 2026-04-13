/// Pure unit conversion helpers for culinary recipes.
///
/// Supported units (Czech):
/// - Weight: `g`, `kg`
/// - Volume: `ml`, `l`, `lžička` (teaspoon), `lžíce` (tablespoon), `hrnek` (cup)
///
/// Density-based conversions:
/// - Volume → Weight requires [densityGml] (grams per milliliter).
/// - Weight → Volume requires [densityGml] (grams per milliliter).
///
/// Returns `null` when a conversion is unknown or not possible.
abstract final class UnitConverter {
  // Standard culinary volume constants.
  static const double teaspoonMl = 5.0; // lžička
  static const double tablespoonMl = 15.0; // lžíce
  static const double cupMl = 250.0; // hrnek

  /// Converts [amount] from [fromUnit] to [toUnit].
  ///
  /// - If `fromUnit == toUnit` (after trimming + lowercasing), returns [amount].
  /// - Returns `null` if units are unknown, incompatible, or density is required
  ///   but missing/invalid.
  static double? convert({
    required double amount,
    required String fromUnit,
    required String toUnit,
    double? densityGml,
  }) {
    if (amount.isNaN || amount.isInfinite) return null;

    final from = _normalizeUnit(fromUnit);
    final to = _normalizeUnit(toUnit);

    if (from == to) return amount;

    // 1) Linear weight conversions.
    final grams = _toGrams(amount, from);
    if (grams != null) {
      final weightOut = _fromGrams(grams, to);
      if (weightOut != null) return weightOut;
    }

    // 2) Linear volume conversions.
    final ml = _toMilliliters(amount, from);
    if (ml != null) {
      final volumeOut = _fromMilliliters(ml, to);
      if (volumeOut != null) return volumeOut;
    }

    // 3) Volume → Weight (requires density).
    final fromMl = _toMilliliters(amount, from);
    if (fromMl != null && _isWeightUnit(to)) {
      final density = _validatedDensity(densityGml);
      if (density == null) return null;

      final gramsOut = fromMl * density;
      return _fromGrams(gramsOut, to);
    }

    // 4) Weight → Volume (requires density).
    final fromGrams = _toGrams(amount, from);
    if (fromGrams != null && _isVolumeUnit(to)) {
      final density = _validatedDensity(densityGml);
      if (density == null) return null;

      final mlOut = fromGrams / density;
      return _fromMilliliters(mlOut, to);
    }

    return null;
  }

  static String _normalizeUnit(String unit) => unit.trim().toLowerCase();

  static bool _isWeightUnit(String unit) => unit == 'g' || unit == 'kg';

  static bool _isVolumeUnit(String unit) =>
      unit == 'ml' ||
      unit == 'l' ||
      unit == 'lžička' ||
      unit == 'lžíce' ||
      unit == 'hrnek';

  static double? _validatedDensity(double? densityGml) {
    if (densityGml == null) return null;
    if (densityGml.isNaN || densityGml.isInfinite) return null;
    if (densityGml <= 0) return null;
    return densityGml;
  }

  static double? _toGrams(double amount, String unit) {
    switch (unit) {
      case 'g':
        return amount;
      case 'kg':
        return amount * 1000.0;
      default:
        return null;
    }
  }

  static double? _fromGrams(double grams, String unit) {
    switch (unit) {
      case 'g':
        return grams;
      case 'kg':
        return grams / 1000.0;
      default:
        return null;
    }
  }

  static double? _toMilliliters(double amount, String unit) {
    switch (unit) {
      case 'ml':
        return amount;
      case 'l':
        return amount * 1000.0;
      case 'lžička':
        return amount * teaspoonMl;
      case 'lžíce':
        return amount * tablespoonMl;
      case 'hrnek':
        return amount * cupMl;
      default:
        return null;
    }
  }

  static double? _fromMilliliters(double ml, String unit) {
    switch (unit) {
      case 'ml':
        return ml;
      case 'l':
        return ml / 1000.0;
      case 'lžička':
        return ml / teaspoonMl;
      case 'lžíce':
        return ml / tablespoonMl;
      case 'hrnek':
        return ml / cupMl;
      default:
        return null;
    }
  }
}
