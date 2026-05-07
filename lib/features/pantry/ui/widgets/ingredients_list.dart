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

  final Set<String> _expandedIngredientIds = {};

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

  List<_PantryDisplayItem> get _displayItems {
    return _buildDisplayItems(widget._items);
  }

  List<String> get _categories {
    final categories = _displayItems
        .map((item) => item.representative.ingredient.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    categories.sort((a, b) {
      return _categoryChipLabel(a).compareTo(_categoryChipLabel(b));
    });

    return categories;
  }

  List<_PantryDisplayItem> get _filteredItems {
    final query = _normalize(_query);

    return _displayItems.where((displayItem) {
      final ingredient = displayItem.representative.ingredient;

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
    return _displayItems
        .where(
          (item) => item.representative.ingredient.category.trim() == category,
        )
        .length;
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _query = '';
      _selectedCategory = null;
    });
  }

  void _toggleGroup(_PantryDisplayItem displayItem) {
    final ingredientId = displayItem.representative.ingredient.id;

    setState(() {
      if (_expandedIngredientIds.contains(ingredientId)) {
        _expandedIngredientIds.remove(ingredientId);
      } else {
        _expandedIngredientIds.add(ingredientId);
      }
    });
  }

  Future<void> _removeDisplayItem(_PantryDisplayItem displayItem) async {
    for (final item in displayItem.items) {
      await widget.onRemove(item.id);
    }

    setState(() {
      _expandedIngredientIds.remove(displayItem.representative.ingredient.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;
    final categories = _categories;
    final totalVisibleItems = _displayItems.length;

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
                    label: Text('📦 Vše ($totalVisibleItems)'),
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
                    final displayItem = filteredItems[index];
                    final isGroup = displayItem.items.length > 1;
                    final ingredientId =
                        displayItem.representative.ingredient.id;
                    final isExpanded =
                        _expandedIngredientIds.contains(ingredientId);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IngredientCard(
                          item: displayItem.representative,
                          displayAmount: displayItem.displayAmount,
                          displayUnit: displayItem.displayUnit,
                          displayText: displayItem.amountText,
                          stateText: displayItem.stateText,
                          showExpiration: true,
                          enableUpdate: !isGroup,
                          onRemove: widget.onRemove,
                          onRemoveGroup: () => _removeDisplayItem(displayItem),
                          onUpdate: widget.onUpdate,
                          onTapOverride:
                              isGroup ? () => _toggleGroup(displayItem) : null,
                          trailingIcon: isGroup
                              ? AnimatedRotation(
                                  turns: isExpanded ? 0.25 : 0,
                                  duration: const Duration(milliseconds: 180),
                                  child: const Icon(Icons.chevron_right),
                                )
                              : null,
                        ),
                        if (isGroup && isExpanded)
                          Padding(
                            padding: const EdgeInsets.only(left: 28, right: 8),
                            child: Column(
                              children: displayItem.items.map((item) {
                                return IngredientCard(
                                  item: item,
                                  showExpiration: true,
                                  dense: true,
                                  onRemove: widget.onRemove,
                                  onUpdate: widget.onUpdate,
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PantryDisplayItem {
  const _PantryDisplayItem({
    required this.representative,
    required this.items,
    required this.displayAmount,
    required this.displayUnit,
    required this.amountText,
    this.stateText,
  });

  final UserIngredient representative;
  final List<UserIngredient> items;
  final num displayAmount;
  final String displayUnit;

  /// Amount text shown on the right side of the row.
  ///
  /// Example:
  /// - "100 ml"
  /// - "1 ks + 200 g"
  /// - "2 ks"
  final String amountText;

  /// Optional state text shown in the subtitle metadata row.
  ///
  /// Example:
  /// - "otevřeno"
  /// - "část otevřena"
  final String? stateText;
}

List<_PantryDisplayItem> _buildDisplayItems(List<UserIngredient> items) {
  final grouped = <String, List<UserIngredient>>{};

  for (final item in items) {
    grouped.putIfAbsent(item.ingredient.id, () => []).add(item);
  }

  final displayItems = grouped.values.map((groupItems) {
    final sortedItems = [...groupItems]..sort((a, b) {
        final aExpires = a.expiresAt;
        final bExpires = b.expiresAt;

        if (aExpires == null && bExpires == null) {
          return a.createdAt.compareTo(b.createdAt);
        }

        if (aExpires == null) return 1;
        if (bExpires == null) return -1;

        final byExpiration = aExpires.compareTo(bExpires);
        if (byExpiration != 0) return byExpiration;

        return a.createdAt.compareTo(b.createdAt);
      });

    final representative = sortedItems.first;
    final ingredient = representative.ingredient;

    if (ingredient.isPerPackage) {
      final wholeKs = sortedItems
          .where((item) => item.unit.trim().toLowerCase() == 'ks')
          .fold<num>(
            0,
            (sum, item) => sum + item.amount,
          );

      final leftoverByUnit = <String, num>{};

      for (final item in sortedItems) {
        final unit = item.unit.trim().toLowerCase();

        if (item.isLeftover && (unit == 'g' || unit == 'ml')) {
          leftoverByUnit[unit] = (leftoverByUnit[unit] ?? 0) + item.amount;
        }
      }

      final amountParts = <String>[];

      if (wholeKs > 0) {
        amountParts.add('${_formatNumber(wholeKs)} ks');
      }

      final leftoverGrams = leftoverByUnit['g'] ?? 0;
      if (leftoverGrams > 0) {
        amountParts.add(_formatAmountWithUnit(leftoverGrams, 'g'));
      }

      final leftoverMl = leftoverByUnit['ml'] ?? 0;
      if (leftoverMl > 0) {
        amountParts.add(_formatAmountWithUnit(leftoverMl, 'ml'));
      }

      final hasLeftover = leftoverGrams > 0 || leftoverMl > 0;

      final amountText = amountParts.isEmpty ? '0 ks' : amountParts.join(' + ');

      final visualPackageCount =
          wholeKs + (leftoverGrams > 0 ? 1 : 0) + (leftoverMl > 0 ? 1 : 0);

      final stateText = hasLeftover
          ? wholeKs > 0
              ? 'část otevřena'
              : 'otevřeno'
          : null;

      return _PantryDisplayItem(
        representative: representative,
        items: sortedItems,
        displayAmount: visualPackageCount,
        displayUnit: 'ks',
        amountText: amountText,
        stateText: stateText,
      );
    }

    final preferredUnit = ingredient.derivedUnit.trim().toLowerCase();

    final matchingPreferredUnit = sortedItems
        .where((item) => item.unit.trim().toLowerCase() == preferredUnit)
        .toList();

    if (matchingPreferredUnit.isNotEmpty) {
      final amount = matchingPreferredUnit.fold<num>(
        0,
        (sum, item) => sum + item.amount,
      );

      final displayUnit = ingredient.derivedUnit;
      final amountText = _formatAmountWithUnit(amount, displayUnit);

      return _PantryDisplayItem(
        representative: representative,
        items: sortedItems,
        displayAmount: amount,
        displayUnit: displayUnit,
        amountText: amountText,
      );
    }

    final firstUnit = representative.unit.trim().toLowerCase();

    final matchingFirstUnit = sortedItems
        .where((item) => item.unit.trim().toLowerCase() == firstUnit)
        .toList();

    final amount = matchingFirstUnit.fold<num>(
      0,
      (sum, item) => sum + item.amount,
    );

    final displayUnit = representative.unit;
    final amountText = _formatAmountWithUnit(amount, displayUnit);

    return _PantryDisplayItem(
      representative: representative,
      items: sortedItems,
      displayAmount: amount,
      displayUnit: displayUnit,
      amountText: amountText,
    );
  }).toList();

  displayItems.sort((a, b) {
    final aExpires = a.representative.expiresAt;
    final bExpires = b.representative.expiresAt;

    if (aExpires == null && bExpires == null) {
      return a.representative.ingredient.name
          .toLowerCase()
          .compareTo(b.representative.ingredient.name.toLowerCase());
    }

    if (aExpires == null) return 1;
    if (bExpires == null) return -1;

    final byExpiration = aExpires.compareTo(bExpires);
    if (byExpiration != 0) return byExpiration;

    return a.representative.ingredient.name
        .toLowerCase()
        .compareTo(b.representative.ingredient.name.toLowerCase());
  });

  return displayItems;
}

String _formatNumber(num value) {
  final intValue = value.toInt();

  if (value == intValue) return intValue.toString();

  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

String _formatAmountWithUnit(num amount, String unit) {
  final normalizedUnit = unit.trim().toLowerCase();

  if (normalizedUnit == 'g' && amount >= 1000 && amount % 1000 == 0) {
    return '${_formatNumber(amount / 1000)} kg';
  }

  if (normalizedUnit == 'ml' && amount >= 1000 && amount % 1000 == 0) {
    return '${_formatNumber(amount / 1000)} l';
  }

  return '${_formatNumber(amount)} $unit';
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