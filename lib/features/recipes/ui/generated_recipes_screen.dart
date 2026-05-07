import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/recipes/domain/generated_recipe.dart';
import 'package:kuchtik/features/recipes/ui/generated_recipe_detail_screen.dart';
import 'package:kuchtik/features/recipes/ui/view_models/generated_recipes_view_model.dart';
import 'package:kuchtik/features/recipes/ui/widgets/generated_recipe_card.dart';

class GeneratedRecipesScreen extends ConsumerStatefulWidget {
  const GeneratedRecipesScreen({
    super.key,
    this.initialMealType,
  });

  final String? initialMealType;

  @override
  ConsumerState<GeneratedRecipesScreen> createState() =>
      _GeneratedRecipesScreenState();
}

class _GeneratedRecipesScreenState
    extends ConsumerState<GeneratedRecipesScreen> {
  late final PageController _pageController;

  int _currentIndex = 0;
  bool _didTriggerGeneration = false;
  String? _selectedMealType;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType;
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didTriggerGeneration) {
      _didTriggerGeneration = true;
      Future.microtask(_generateRecipes);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _generateRecipes() async {
    setState(() {
      _currentIndex = 0;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }

    await ref
        .read(generatedRecipesViewModelProvider.notifier)
        .generateRecipes(mealType: _selectedMealType);
  }

  void _selectMealType(String? mealType) {
    if (_selectedMealType == mealType) return;

    setState(() {
      _selectedMealType = mealType;
      _currentIndex = 0;
    });

    ref.read(generatedRecipesViewModelProvider.notifier).clearResults();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Návrhy receptů'),
      ),
      body: CustomScrollView(
        slivers: [        
          SliverToBoxAdapter(
            child: _GeneratedMealTypeFilter(
              selectedMealType: _selectedMealType,
              onSelected: _selectMealType,
            ),
          ),

          SliverToBoxAdapter(
            child: recipesAsync.when(
              loading: () => const _LoadingSection(),
              error: (error, _) => _ErrorSection(
                onRetry: _generateRecipes,
              ),
              data: (recipes) {
                if (recipes == null || recipes.isEmpty) {
                  return _EmptySection(
                    onGenerate: _generateRecipes,
                  );
                }

                final safeIndex = _currentIndex.clamp(0, recipes.length - 1);
                final selectedRecipe = recipes[safeIndex];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 400,
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
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _openDetail(selectedRecipe),
                          icon: const Icon(Icons.menu_book_outlined),
                          label: const Text('Zobrazit detail'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton.icon(
                        onPressed: _generateRecipes,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Zkusit znovu'),
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

class _GeneratedMealTypeFilter extends StatelessWidget {
  const _GeneratedMealTypeFilter({
    required this.selectedMealType,
    required this.onSelected,
  });

  final String? selectedMealType;
  final ValueChanged<String?> onSelected;

  static const filters = <({String? value, String label})>[
    (value: null, label: 'Vše'),
    (value: 'breakfast', label: 'Snídaně'),
    (value: 'main_course', label: 'Hlavní chod'),
    (value: 'soup', label: 'Polévka'),
    (value: 'snack', label: 'Svačina'),
    (value: 'dessert', label: 'Dezert'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Co chceš připravit?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = selectedMealType == filter.value;

                return ChoiceChip(
                  label: Text(filter.label),
                  selected: isSelected,
                  showCheckmark: false,
                  onSelected: (_) => onSelected(filter.value),
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
    required this.onGenerate,
  });

  final Future<void> Function() onGenerate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.auto_awesome_outlined, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Vyber typ jídla a vygeneruj návrhy podle surovin, které máš doma.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Vygenerovat návrhy'),
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