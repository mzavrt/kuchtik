import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/dashboard/ui/states/dashboard_state.dart';
import 'package:kuchtik/features/dashboard/ui/view_models/dashboard_view_model.dart';
import 'package:kuchtik/features/dashboard/ui/widgets/recipe_card.dart';
import 'package:kuchtik/features/dashboard/ui/widgets/section_header_delegate.dart';
import 'package:kuchtik/features/recipes/domain/recipe_dashboard_item.dart';
import 'package:kuchtik/features/recipes/ui/recipe_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeViewModelProvider);

    return state.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('Chyba: $error'))),
      data: (data) => Scaffold(
        body: CustomScrollView(
          slivers: [
            if (data.urgentRecipes.isNotEmpty)
              _RecipeSection(
                title: '🚨 Hoří to! / Zachraň mě!',
                recipes: data.urgentRecipes,
                variant: RecipeCardVariant.urgent,
              ),
            if (data.perfectMatchRecipes.isNotEmpty)
              _RecipeSection(
                title: '✅ 100% Shoda (Rovnou k plotně)',
                recipes: data.perfectMatchRecipes,
                variant: RecipeCardVariant.perfectMatch,
              ),
            if (data.missingOneRecipes.isNotEmpty)
              _RecipeSection(
                title: '🤏 Chybí jen maličkost',
                recipes: data.missingOneRecipes,
                variant: RecipeCardVariant.missingOne,
              ),
            if (data.discoveryRecipes.isNotEmpty)
              _RecipeSection(
                title: 'Máš chuť na něco nového?',
                recipes: data.discoveryRecipes,
                variant: RecipeCardVariant.discovery,
              ),
          ],
        ),
      ),
    );
  }
}

class _RecipeSection extends StatelessWidget {
  const _RecipeSection({
    required this.title,
    required this.recipes,
    required this.variant,
  });

  final String title;
  final List<RecipeDashboardItem> recipes;
  final RecipeCardVariant variant;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: SectionHeaderDelegate(title),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: RecipeCard(
                    recipe: recipe,
                    variant: variant,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RecipeDetailScreen(recipeId: recipe.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
