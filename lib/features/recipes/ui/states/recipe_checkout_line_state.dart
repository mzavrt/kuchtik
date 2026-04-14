import 'package:kuchtik/core/utils/unit_converter.dart';

/// Prepared UI state for a single ingredient line in the recipe checkout sheet.
///
/// UX rule: never convert pantry inventory to recipe units.
/// Instead, we convert the recipe requirement into the pantry unit.
class RecipeCheckoutLineState {
  const RecipeCheckoutLineState({
    required this.recipeAmount,
    required this.recipeUnit,
    required this.pantryAmount,
    required this.pantryUnit,
    required this.densityGml,
    required this.requiresText,
    required this.pantryText,
    required this.suggestedDeduction,
  });

  final double recipeAmount;
  final String recipeUnit;

  final double pantryAmount;
  final String pantryUnit;

  /// Ingredient density in g/ml (nullable).
  final double? densityGml;

  final String requiresText;

  final String pantryText;

  final int suggestedDeduction;

  static RecipeCheckoutLineState prepare({
    required double recipeAmount,
    required String recipeUnit,
    required double pantryAmount,
    required String pantryUnit,
    double? densityGml,
  }) {
    final normalizedRecipeUnit = recipeUnit.trim();
    final normalizedPantryUnit = pantryUnit.trim();

    final recipeAmountText = _formatAmount(recipeAmount);
    final pantryAmountText = pantryAmount.round().toString();

    final pantryText = 'V lednici: $pantryAmountText $normalizedPantryUnit'.trim();

    final sameUnit = _normalizeUnit(normalizedRecipeUnit) ==
        _normalizeUnit(normalizedPantryUnit);

    double? converted;
    bool conversionApplied = false;

    if (sameUnit) {
      converted = recipeAmount;
      conversionApplied = false;
    } else if (normalizedRecipeUnit.isNotEmpty && normalizedPantryUnit.isNotEmpty) {
      converted = UnitConverter.convert(
        amount: recipeAmount,
        fromUnit: normalizedRecipeUnit,
        toUnit: normalizedPantryUnit,
        densityGml: densityGml,
      );
      conversionApplied = converted != null;
    }

    final int pantryStockRounded = pantryAmount.round();

    // Default value is the converted requirement, rounded to whole.
    // If we cannot convert (null) and units differ, default to 0 so the user
    // explicitly chooses a deduction in their pantry unit.
    final int suggested = sameUnit
        ? recipeAmount.round()
        : (converted != null ? converted.round() : 0);

    final int suggestedClamped = suggested.clamp(0, pantryStockRounded);

    final requiresText = conversionApplied
      ? 'Potřeba: $recipeAmountText $normalizedRecipeUnit (~ $suggestedClamped $normalizedPantryUnit)'
        .trim()
      : 'Potřeba: $recipeAmountText $normalizedRecipeUnit'.trim();

    return RecipeCheckoutLineState(
      recipeAmount: recipeAmount,
      recipeUnit: normalizedRecipeUnit,
      pantryAmount: pantryAmount,
      pantryUnit: normalizedPantryUnit,
      densityGml: densityGml,
      requiresText: requiresText,
      pantryText: pantryText,
      suggestedDeduction: suggestedClamped,
    );
  }

  static String _normalizeUnit(String unit) => unit.trim().toLowerCase();

  static String _formatAmount(num value) {
    // Keep recipe display readable: show int when possible.
    final intValue = value.toInt();
    if (value == intValue) return intValue.toString();
    return value.toString();
  }
}
