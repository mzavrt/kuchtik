import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuchtik/features/recipes/domain/generated_recipe.dart';
import 'package:kuchtik/features/recipes/ui/view_models/generated_recipes_view_model.dart';
import 'package:kuchtik/features/recipes/ui/widgets/generated_recipe_card.dart';
import 'package:kuchtik/features/recipes/ui/generated_recipe_detail_screen.dart';

class GeneratedRecipesScreen extends ConsumerStatefulWidget {
  const GeneratedRecipesScreen({super.key});

  @override
  ConsumerState<GeneratedRecipesScreen> createState() =>
      _GeneratedRecipesScreenState();
}

class _GeneratedRecipesScreenState extends ConsumerState<GeneratedRecipesScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _didTriggerGeneration = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didTriggerGeneration) {
      _didTriggerGeneration = true;
      Future.microtask(() {
        ref
            .read(generatedRecipesViewModelProvider.notifier)
            .generateRecipes();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openDetail(GeneratedRecipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GeneratedRecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(generatedRecipesViewModelProvider);
    final notifier = ref.read(generatedRecipesViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Návrhy receptů'),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Na základě ingrediencí, které máš doma.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: recipesAsync.when(
              loading: () => const _LoadingSection(),
              error: (error, _) => _ErrorSection(
                onRetry: notifier.regenerateRecipes,
              ),
              data: (recipes) {
                if (recipes == null || recipes.isEmpty) {
                  return _EmptySection(
                    onRetry: notifier.regenerateRecipes,
                  );
                }

                final safeIndex = _currentIndex.clamp(0, recipes.length - 1);
                final selectedRecipe = recipes[safeIndex];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 430,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: recipes.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: GeneratedRecipeCard(
                              recipe: recipe,
                              isActive: index == safeIndex,
                              onTapDetail: () => _openDetail(recipe),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PageIndicator(
                      count: recipes.length,
                      currentIndex: safeIndex,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FilledButton.icon(
                        onPressed: () => _openDetail(selectedRecipe),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: const Text('Zobrazit detail'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton(
                        onPressed: notifier.regenerateRecipes,
                        child: const Text('Zkusit znovu'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            SizedBox(height: 32),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generuji návrhy receptů...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({
    required this.onRetry,
  });

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            const Text('Nepodařilo se vygenerovat recepty.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Zkusit znovu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.onRetry,
  });

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.no_meals_outlined, size: 40),
            const SizedBox(height: 12),
            const Text('Nepodařilo se najít žádné návrhy.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Zkusit znovu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}