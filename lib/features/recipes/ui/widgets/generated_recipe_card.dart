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

    return AnimatedScale(
      scale: isActive ? 1 : 0.97,
      duration: const Duration(milliseconds: 200),
      child: Card(
        clipBehavior: Clip.antiAlias,
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
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
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
                      label: '${recipe.expiringIngredientCount} expiring',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                recipe.inventoryReason,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                'Ingredience',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recipe.ingredients.take(4).map((ingredient) {
                  final label =
                      '${ingredient.emoji != null ? '${ingredient.emoji} ' : ''}${ingredient.name}';
                  return Chip(
                    label: Text(label),
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onTapDetail,
                  child: const Text('Zobrazit detail'),
                ),
              ),
            ],
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
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}