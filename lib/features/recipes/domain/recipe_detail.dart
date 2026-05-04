import 'package:kuchtik/features/recipes/domain/recipe_ingredient.dart';

class RecipeDetail {
  final String id;
  final String title;
  final int servings;
  final List<String> steps;
  final List<RecipeIngredient> ingredients;
  final String imageUrl;
  final String createdBy;

  RecipeDetail({
    required this.id,
    required this.title,
    required this.servings,
    required this.steps,
    required this.ingredients,
    required this.imageUrl,
    required this.createdBy,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json, {String? resolvedImageUrl}) {

    final ingredientsList = json['recipe_ingredient'] as List<dynamic>? ?? [];
    final stepsJson = json['instruction_steps'] as List<dynamic>? ?? const [];
    
    final parsedIngredients = ingredientsList
        .map((i) => RecipeIngredient.fromJson(i as Map<String, dynamic>))
        .toList();


    return RecipeDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      servings: json['servings'] as int? ?? 0,
      steps: stepsJson
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      ingredients: parsedIngredients,
      imageUrl: resolvedImageUrl ?? (json['image_url'] ?? '') as String,
      createdBy: json['created_by'] as String? ?? '',
    );
  }
  

}