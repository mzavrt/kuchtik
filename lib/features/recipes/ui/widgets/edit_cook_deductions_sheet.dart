import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/pantry/domain/pantry_deduction.dart';
import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';
import 'package:kuchtik/features/recipes/domain/recipe_detail.dart';
import 'package:kuchtik/features/recipes/ui/states/recipe_checkout_line_state.dart';

class EditCookDeductionsSheet extends ConsumerStatefulWidget {
  const EditCookDeductionsSheet({
    super.key,
    required this.recipe,
    required this.pantryItems,
  });

  final RecipeDetail recipe;
  final List<UserIngredient> pantryItems;

  @override
  ConsumerState<EditCookDeductionsSheet> createState() => _EditCookDeductionsSheetState();
}

class _CookLine {
  _CookLine({
    required this.ingredientId,
    required this.name,
    required this.requiredAmount,
    required this.requiredUnit,
    required this.pantryUnit,
    required this.pantryAmount,
    required this.requiresText,
    required this.pantryText,
    required this.controller,
  });

  final String ingredientId;
  final String name;
  final double requiredAmount;
  final String requiredUnit;
  final String pantryUnit;
  final double pantryAmount;
  final String requiresText;
  final String pantryText;
  final TextEditingController controller;

  static const double _epsilon = 1e-9;

  double get deductionAmount {
    final raw = controller.text.trim().replaceAll(',', '.');
    return double.tryParse(raw) ?? 0;
  }

  bool get hasShortage => deductionAmount > pantryAmount + _epsilon;

  PantryDeduction? toDeduction() {
    final amount = deductionAmount;
    if (amount <= _epsilon) return null;
    if (ingredientId.trim().isEmpty) return null;
    if (pantryUnit.trim().isEmpty) return null;

    // CRITICAL: send to DB in pantry units.
    return PantryDeduction(
      ingredientId: ingredientId,
      amount: amount,
      unit: pantryUnit.trim(),
    );
  }
}

class _EditCookDeductionsSheetState extends ConsumerState<EditCookDeductionsSheet> {
  late final List<_CookLine> _lines;

  @override
  void initState() {
    super.initState();

    // UX rule: show pantry stock in pantry units.
    // If the user has the same ingredient in multiple units, we show one line per unit.
    final builtLines = <_CookLine>[];

    for (final ri in widget.recipe.ingredients) {
      final ingredientId = ri.ingredientId;
      final requiredAmount = ri.amount?.toDouble() ?? 0;
      final requiredUnit = (ri.unit ?? '').trim();

      final pantryForIngredient = widget.pantryItems
          .where((p) => p.ingredient.id == ingredientId)
          .toList(growable: false);

      if (pantryForIngredient.isEmpty) {
        // No pantry stock: still show a line (max=0) so user can confirm.
        final pantryUnit = requiredUnit;
        final lineState = RecipeCheckoutLineState.prepare(
          recipeAmount: requiredAmount,
          recipeUnit: requiredUnit,
          pantryAmount: 0,
          pantryUnit: pantryUnit,
          densityGml: null,
        );

        final controller = TextEditingController(text: '0');

        builtLines.add(
          _CookLine(
            ingredientId: ingredientId,
            name: ri.name,
            requiredAmount: requiredAmount,
            requiredUnit: requiredUnit,
            pantryUnit: pantryUnit,
            pantryAmount: 0,
            requiresText: lineState.requiresText,
            pantryText: lineState.pantryText,
            controller: controller,
          ),
        );

        continue;
      }

      // Group pantry by unit.
      final Map<String, double> pantryByUnit = {};
      for (final p in pantryForIngredient) {
        final unit = p.unit.trim();
        if (unit.isEmpty) continue;
        pantryByUnit[unit] = (pantryByUnit[unit] ?? 0) + p.amount;
      }

      for (final entry in pantryByUnit.entries) {
        final pantryUnit = entry.key;
        final pantryAmount = entry.value;
        final lineState = RecipeCheckoutLineState.prepare(
          recipeAmount: requiredAmount,
          recipeUnit: requiredUnit,
          pantryAmount: pantryAmount,
          pantryUnit: pantryUnit,
          densityGml: null,
        );

        final controller = TextEditingController(
          text: lineState.suggestedDeduction.toString(),
        );

        builtLines.add(
          _CookLine(
            ingredientId: ingredientId,
            name: ri.name,
            requiredAmount: requiredAmount,
            requiredUnit: requiredUnit,
            pantryUnit: pantryUnit,
            pantryAmount: pantryAmount,
            requiresText: lineState.requiresText,
            pantryText: lineState.pantryText,
            controller: controller,
          ),
        );
      }
    }

    _lines = builtLines;

    for (final line in _lines) {
      line.controller.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasShortages = _lines.any((l) => l.hasShortage);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uvařeno',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Zkontrolujte suroviny a případně upravte odečty.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _lines.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final line = _lines[index];

                  return Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  line.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (line.pantryUnit.isNotEmpty)
                                Text(
                                  line.pantryUnit,
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            line.pantryText,
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            line.requiresText,
                            style: theme.textTheme.bodySmall,
                          ),
                          if (line.hasShortage) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Nedostatek: odečet je větší než množství v lednici.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: line.controller,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: false,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Odečíst',
                                    suffixText:
                                        line.pantryUnit.isNotEmpty ? line.pantryUnit : null,
                                    helperText:
                                        'Max: ${_formatAmount(line.pantryAmount)} ${line.pantryUnit}'
                                            .trim(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: line.pantryAmount <= 0
                                    ? null
                                    : () {
                                        setState(() {
                                          line.controller.text =
                                              _formatAmount(line.pantryAmount);
                                        });
                                      },
                                child: const Text('MAX'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasShortages
                    ? null
                    : () {
                        final deductions = _lines
                            .map((l) => l.toDeduction())
                            .whereType<PantryDeduction>()
                            .toList(growable: false);

                        Navigator.of(context).pop(deductions);
                      },
                child: const Text('Potvrdit'),
              ),
            ),
            if (hasShortages) ...[
              const SizedBox(height: 8),
              Text(
                'Upravte odečty tak, aby nebyly v nedostatku.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAmount(num value) {
    final intValue = value.toInt();
    if (value == intValue) return intValue.toString();
    return value.toString();
  }
}
