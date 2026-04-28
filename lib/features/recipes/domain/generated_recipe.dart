import 'generated_recipe_ingredient.dart';

class GeneratedRecipe {
  const GeneratedRecipe({
    required this.id,
    required this.title,
    required this.description,
    required this.timeMinutes,
    required this.inventoryReason,
    required this.ingredients,
    required this.steps,
    required this.usedInventoryItems,
    required this.usedExpiringItems,
  });

  final String id;
  final String title;
  final String description;
  final int timeMinutes;
  final String inventoryReason;
  final List<GeneratedRecipeIngredient> ingredients;
  final List<String> steps;
  final List<String> usedInventoryItems;
  final List<String> usedExpiringItems;

  List<String> get ingredientNames =>
      ingredients.map((e) => e.name).toList(growable: false);

  int get inventoryIngredientCount =>
      ingredients.where((e) => e.fromInventory).length;

  int get missingIngredientCount =>
      ingredients.where((e) => !e.fromInventory).length;

  bool get hasMissingIngredients => missingIngredientCount > 0;

  int get expiringIngredientCount => usedExpiringItems.length;

  factory GeneratedRecipe.fromJson(Map<String, dynamic> json) {
    final ingredientsJson = (json['ingredients'] as List<dynamic>? ?? const []);
    final stepsJson = (json['steps'] as List<dynamic>? ?? const []);
    final usedInventoryJson =
        (json['usedInventoryItems'] as List<dynamic>? ?? const []);
    final usedExpiringJson =
        (json['usedExpiringItems'] as List<dynamic>? ?? const []);

    return GeneratedRecipe(
      id: ((json['id'] as String?)?.trim().isNotEmpty ?? false)
          ? (json['id'] as String).trim()
          : DateTime.now().microsecondsSinceEpoch.toString(),
      title: (json['title'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      timeMinutes: json['timeMinutes'] as int? ?? 0,
      inventoryReason: (json['inventoryReason'] as String? ?? '').trim(),
      ingredients: ingredientsJson
          .whereType<Map<String, dynamic>>()
          .map(GeneratedRecipeIngredient.fromJson)
          .toList(growable: false),
      steps: stepsJson
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      usedInventoryItems: usedInventoryJson
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      usedExpiringItems: usedExpiringJson
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timeMinutes': timeMinutes,
      'inventoryReason': inventoryReason,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'steps': steps,
      'usedInventoryItems': usedInventoryItems,
      'usedExpiringItems': usedExpiringItems,
    };
  }
}