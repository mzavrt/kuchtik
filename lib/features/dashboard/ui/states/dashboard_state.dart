import 'package:kuchtik/features/recipes/domain/recipe_dashboard_item.dart';

class DashboardState {
  DashboardState({
    required this.urgentRecipes,
    required this.perfectMatchRecipes,
    required this.missingOneRecipes,
    required this.discoveryRecipes,
  });

  final List<RecipeDashboardItem> urgentRecipes;
  final List<RecipeDashboardItem> perfectMatchRecipes;
  final List<RecipeDashboardItem> missingOneRecipes;
  final List<RecipeDashboardItem> discoveryRecipes;
}
