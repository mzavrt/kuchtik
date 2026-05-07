import 'package:kuchtik/features/recipes/domain/recipe_dashboard_item.dart';
import 'package:kuchtik/features/dashboard/domain/ingredient_chip.dart';

class DashboardState {
  const DashboardState({
    required this.urgentRecipes,
    required this.perfectMatchRecipes,
    required this.missingOneRecipes,
    required this.discoveryRecipes,
    required this.ingredientFilters,
  });

  final List<RecipeDashboardItem> urgentRecipes;
  final List<RecipeDashboardItem> perfectMatchRecipes;
  final List<RecipeDashboardItem> missingOneRecipes;
  final List<RecipeDashboardItem> discoveryRecipes;
  final List<IngredientChip> ingredientFilters;
}