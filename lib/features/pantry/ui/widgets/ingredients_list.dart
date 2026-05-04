import 'package:flutter/material.dart';
import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';
import 'package:kuchtik/features/pantry/ui/widgets/ingredient_card.dart';

class IngredientsList extends StatefulWidget {
  const IngredientsList({
    super.key,
    required List<UserIngredient> items,
    required this.onRemove,
    required this.onUpdate,
  }) : _items = items;

  final List<UserIngredient> _items;
  final Future<void> Function(String) onRemove;
  final Future<void> Function(UserIngredient) onUpdate;

  @override
  State<IngredientsList> createState() => _IngredientsListState();
}

class _IngredientsListState extends State<IngredientsList> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  String _categoryChipLabel(String category) {
    return switch (category.trim().toLowerCase()) {
      'spices' => '🧂 Koření',
      'pantry' => '🥫 Trvanlivé',
      'vegetables' => '🥕 Zelenina',
      'dairy' => '🥛 Mléčné',
      'fruit' => '🍎 Ovoce',
      'meat' => '🥩 Maso',
      'bakery' => '🥐 Pečivo',
      _ => category,
    };
  }

  List<String> get _categories {
    final categories = widget._items
        .map((item) => item.ingredient.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    categories.sort((a, b) {
      return _categoryChipLabel(a).compareTo(_categoryChipLabel(b));
    });

    return categories;
  }

  List<UserIngredient> get _filteredItems {
    final query = _normalize(_query);

    return widget._items.where((item) {
      final ingredient = item.ingredient;

      final matchesCategory = _selectedCategory == null ||
          ingredient.category.trim() == _selectedCategory;

      final matchesSearch = query.isEmpty ||
          _normalize(ingredient.name).contains(query) ||
          ingredient.searchAliases.any(
            (alias) => _normalize(alias).contains(query),
          ) ||
          _normalize(ingredient.category).contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  int _countForCategory(String category) {
    return widget._items
        .where((item) => item.ingredient.category.trim() == category)
        .length;
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _query = '';
      _selectedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;
    final categories = _categories;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Hledat ingredience...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _query = '';
                        });
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
        ),

        if (categories.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final selected = _selectedCategory == null;

                  return FilterChip(
                    label: Text('📦 Vše (${widget._items.length})'),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                  );
                }

                final category = categories[index - 1];
                final selected = _selectedCategory == category;

                return FilterChip(
                  label: Text(
                    '${_categoryChipLabel(category)} '
                    '(${_countForCategory(category)})',
                  ),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = selected ? null : category;
                    });
                  },
                );
              },
            ),
          ),

        const SizedBox(height: 4),

        Expanded(
          child: filteredItems.isEmpty
              ? _NoMatchingIngredientsState(
                  hasQuery: _query.trim().isNotEmpty,
                  hasCategory: _selectedCategory != null,
                  onClearFilters: _clearFilters,
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];

                    return IngredientCard(
                      item: item,
                      onRemove: widget.onRemove,
                      onUpdate: widget.onUpdate,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _NoMatchingIngredientsState extends StatelessWidget {
  const _NoMatchingIngredientsState({
    required this.hasQuery,
    required this.hasCategory,
    required this.onClearFilters,
  });

  final bool hasQuery;
  final bool hasCategory;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Nic nenalezeno',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery && hasCategory
                  ? 'Zkuste upravit hledání nebo vybrat jinou kategorii.'
                  : hasQuery
                      ? 'Zkuste zadat jiný název ingredience.'
                      : 'V této kategorii zatím nejsou žádné ingredience.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClearFilters,
              child: const Text('Vymazat filtry'),
            ),
          ],
        ),
      ),
    );
  }
}