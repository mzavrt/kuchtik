import 'package:flutter/material.dart';
import 'package:kuchtik/features/recipes/domain/generated_recipe.dart';

class GeneratedRecipeDetailScreen extends StatelessWidget {
  const GeneratedRecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  final GeneratedRecipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                Text(
                  recipe.title,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  recipe.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            recipe.inventoryReason,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Ingredience',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...recipe.ingredients.map((ingredient) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      ingredient.emoji ?? '•',
                      style: theme.textTheme.titleLarge,
                    ),
                    title: Text(ingredient.name),
                    subtitle: Text(ingredient.amount),
                    trailing: ingredient.fromInventory
                        ? const Icon(Icons.check_circle_outline)
                        : null,
                  );
                }),
                const SizedBox(height: 24),
                Text(
                  'Postup',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...recipe.steps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          child: Text('${entry.key + 1}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}