import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/dashboard/ui/widgets/recipe_card.dart';
import 'package:kuchtik/features/dashboard/ui/widgets/section_header_delegate.dart';
import 'package:kuchtik/features/recipes/domain/recipe_dashboard_item.dart';

typedef Recipe = RecipeDashboardItem;

final _selectedIngredientProvider =
    NotifierProvider.autoDispose<_SelectedIngredientNotifier, String?>(
  _SelectedIngredientNotifier.new,
);

class _SelectedIngredientNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void toggle(String ingredient) {
    state = state == ingredient ? null : ingredient;
  }
}

class IngredientFilteredSection extends ConsumerWidget {
  const IngredientFilteredSection({
    super.key,
    required this.availableIngredients,
    required this.allRecipes,
    required this.onRecipeTap,
  });

  final List<String> availableIngredients;
  final List<Recipe> allRecipes;
  final ValueChanged<Recipe> onRecipeTap;

  String _stripLeadingEmoji(String value) {
    // Removes leading emoji/symbols from strings like "🍅 Rajčata".
    return value.replaceFirst(RegExp(r'^[^\p{L}\p{N}]+', unicode: true), '').trim();
  }

  String _normalize(String value) {
    return removeDiacritics(_stripLeadingEmoji(value)).toLowerCase().trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedIngredientProvider);
    final selectedNorm = selected == null ? null : _normalize(selected);

    final filtered = selectedNorm == null
        ? allRecipes
        : allRecipes
            .where(
              (recipe) => recipe.ingredientNames.any(
                (nameRaw) {
                  final name = _normalize(nameRaw);
                  return name == selectedNorm ||
                      name.contains(selectedNorm) ||
                      selectedNorm.contains(name);
                },
              ),
            )
            .toList(growable: false);

    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: SectionHeaderDelegate('💡 Máš chuť na...'),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: availableIngredients.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final ingredient = availableIngredients[index];
                final isSelected = ingredient == selected;

                return ChoiceChip(
                  label: Text(ingredient),
                  showCheckmark: false,
                  selected: isSelected,
                  onSelected: (_) {
                    ref
                        .read(_selectedIngredientProvider.notifier)
                        .toggle(ingredient);
                  },
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 280,
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Pro tuto surovinu tu nic není.'),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final recipe = filtered[index];
                      return RecipeCard(
                        recipe: recipe,
                        variant: RecipeCardVariant.discovery,
                        onTap: () => onRecipeTap(recipe),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
