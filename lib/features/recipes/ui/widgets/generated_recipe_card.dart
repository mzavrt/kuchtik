import 'package:flutter/material.dart';
import 'package:kuchtik/features/recipes/domain/generated_recipe.dart';

class GeneratedRecipeCard extends StatelessWidget {
  const GeneratedRecipeCard({
    super.key,
    required this.recipe,
    required this.isActive,
    required this.onTapDetail,
  });

  final GeneratedRecipe recipe;
  final bool isActive;
  final VoidCallback onTapDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final visibleIngredients = recipe.ingredients.take(1).toList();
    final hiddenIngredientCount =
        recipe.ingredients.length - visibleIngredients.length;

    return AnimatedScale(
      scale: isActive ? 1 : 0.97,
      duration: const Duration(milliseconds: 200),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTapDetail,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: theme.textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                Text(
                  recipe.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.schedule_outlined,
                      label: '${recipe.timeMinutes} min',
                    ),
                    _InfoChip(
                      icon: Icons.kitchen_outlined,
                      label: '${recipe.inventoryIngredientCount} z lednice',
                    ),
                    if (recipe.expiringIngredientCount > 0)
                      _InfoChip(
                        icon: Icons.warning_amber_rounded,
                        label:
                            '${recipe.expiringIngredientCount} brzy expirují',
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  recipe.inventoryReason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 18),

                Text(
                  'Ingredience',
                  style: theme.textTheme.titleMedium,
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...visibleIngredients.map((ingredient) {
                      final emoji = ingredient.emoji?.trim();
                      final label =
                          '${emoji != null && emoji.isNotEmpty ? '$emoji ' : ''}${ingredient.name}';

                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 155),
                        child: Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }),
                    if (hiddenIngredientCount > 0)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text('+$hiddenIngredientCount další'),
                      ),
                  ],
                ),

                Spacer(),

                
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}