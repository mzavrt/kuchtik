import 'package:kuchtik/features/recipes/domain/recipe_ingredient.dart';

class RecipeDetail {
  final String id;
  final String title;
  final String instructions;
  final List<RecipeIngredient> ingredients;
  final String imageUrl;
  final String createdBy;

  RecipeDetail({
    required this.id,
    required this.title,
    required this.instructions,
    required this.ingredients,
    required this.imageUrl,
    required this.createdBy,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json, {String? resolvedImageUrl}) {

    final ingredientsList = json['recipe_ingredient'] as List<dynamic>? ?? [];
    
    final parsedIngredients = ingredientsList
        .map((i) => RecipeIngredient.fromJson(i as Map<String, dynamic>))
        .toList();


    return RecipeDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      instructions: json['instructions'] as String,
      ingredients: parsedIngredients,
      imageUrl: resolvedImageUrl ?? (json['image_url'] ?? '') as String,
      createdBy: json['created_by'] as String? ?? '',
    );
  }
  

}