import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/pantry/domain/ingredient.dart';
import 'package:kuchtik/features/pantry/ui/view_models/pantry_view_model.dart';
import 'package:kuchtik/features/pantry/ui/view_models/manual_add_view_model.dart';

class ManualAddScreen extends ConsumerStatefulWidget {
  const ManualAddScreen({super.key});

  @override
  ConsumerState<ManualAddScreen> createState() => _ManualAddScreenState();
}

class _ManualAddScreenState extends ConsumerState<ManualAddScreen> {
  final Map<int, TextEditingController> _amountControllers = {};

  String _formatAmount(num value) {
    final intValue = value.toInt();

    if (value == intValue) return intValue.toString();

    return value.toString();
  }

  TextEditingController _amountC(ManualDraftItem item) {
    final controller = _amountControllers.putIfAbsent(
      item.localId,
      () => TextEditingController(
        text: _formatAmount(item.amount),
      ),
    );

    final expectedText = _formatAmount(item.amount);

    if (controller.text != expectedText &&
        controller.selection.baseOffset == -1) {
      controller.text = expectedText;
    }

    return controller;
  }

  void _disposeControllerFor(int id) {
    _amountControllers.remove(id)?.dispose();
  }

  @override
  void dispose() {
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  String _labelForIngredient(Ingredient ingredient) {
    final emoji = (ingredient.emoji ?? '').trim();
    final name = ingredient.name.trim();

    if (emoji.isEmpty) return name;
    if (name.isEmpty) return emoji;

    return '$emoji $name';
  }

  String _estimateLabelFor(ManualDraftItem item) {
    final ingredient = item.ingredient;
    final unit = ingredient.derivedUnit;

    if (unit != 'ks') return '';
    if (!ingredient.hasDefaultPieceValue) return '';

    final amount = item.amount.round();
    final estimatedTotal = amount * ingredient.defaultValuePerPiece!;

    return '≈ ${estimatedTotal.toStringAsFixed(0)}${ingredient.defaultValueUnit ?? ''}';
  }

  Future<void> _openSwapIngredientSheet(
    BuildContext context, {
    required ManualDraftItem item,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Změnit ingredienci',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SearchAnchor(
                shrinkWrap: true,
                builder: (context, controller) {
                  return SearchBar(
                    controller: controller,
                    padding: const WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    hintText: 'Hledat ingredienci',
                    leading: const Icon(Icons.search),
                    onTap: () => controller.openView(),
                    onChanged: (_) => controller.openView(),
                  );
                },
                suggestionsBuilder: (context, controller) {
                  final ingredientsAsync = ref.watch(
                    ingredientSuggestionsProvider(controller.text),
                  );

                  return ingredientsAsync.when(
                    data: (suggestions) {
                      return suggestions.map((suggestion) {
                        return ListTile(
                          title: Text(_labelForIngredient(suggestion)),
                          onTap: () {
                            _disposeControllerFor(item.localId);

                            ref
                                .read(manualAddViewModelProvider.notifier)
                                .changeIngredient(item.localId, suggestion);

                            controller.closeView(suggestion.name);
                            Navigator.of(sheetContext).pop();
                          },
                        );
                      }).toList();
                    },
                    loading: () => const [
                      ListTile(title: Text('Načítám...')),
                    ],
                    error: (error, _) => [
                      ListTile(title: Text('Chyba: $error')),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(BuildContext context) async {
    final vm = ref.read(manualAddViewModelProvider.notifier);

    await vm.submit();

    final after = ref.read(manualAddViewModelProvider);

    if (!context.mounted) return;

    if (after.errorMessage == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manualAddViewModelProvider);
    final vm = ref.read(manualAddViewModelProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Přidat ingredience'),
        actions: [
          TextButton(
            onPressed: state.isSubmitting ? null : () => _submit(context),
            child: state.isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Přidat (${state.items.length})'),
          ),
        ],
      ),
      body: Column(
        children: [
          SearchAnchor(
            shrinkWrap: true,
            builder: (context, controller) {
              return SearchBar(
                controller: controller,
                padding: const WidgetStatePropertyAll<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 16.0),
                ),
                hintText: 'Přidat ingredienci',
                leading: const Icon(Icons.search),
                onTap: () => controller.openView(),
                onChanged: (_) => controller.openView(),
              );
            },
            suggestionsBuilder: (context, controller) {
              final ingredientsAsync = ref.watch(
                ingredientSuggestionsProvider(controller.text),
              );

              return ingredientsAsync.when(
                data: (suggestions) {
                  return suggestions.map((suggestion) {
                    return ListTile(
                      title: Text(_labelForIngredient(suggestion)),
                      onTap: () {
                        vm.addIngredient(suggestion);
                        controller.closeView('');
                        FocusScope.of(context).unfocus();
                      },
                    );
                  }).toList();
                },
                loading: () => const [
                  ListTile(title: Text('Načítám...')),
                ],
                error: (error, _) => [
                  ListTile(title: Text('Chyba: $error')),
                ],
              );
            },
          ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                state.errorMessage!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          Expanded(
            child: state.items.isEmpty
                ? const Center(
                    child: Text('Přidejte ingredience pomocí vyhledávání'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      final ingredient = item.ingredient;
                      final unit = ingredient.derivedUnit;
                      final usesStepper = unit == 'ks';
                      final amountInt = item.amount.round();
                      final estimateLabel = _estimateLabelFor(item);

                      return Dismissible(
                        key: ValueKey(item.localId),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          _disposeControllerFor(item.localId);
                          vm.remove(item.localId);
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.delete,
                            color: theme.colorScheme.onError,
                          ),
                        ),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onLongPress: () => _openSwapIngredientSheet(
                                    context,
                                    item: item,
                                  ),
                                  child: Text(
                                    _labelForIngredient(ingredient),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (usesStepper) ...[
                                      IconButton(
                                        tooltip: 'Méně',
                                        onPressed: amountInt <= 1
                                            ? null
                                            : () => vm.updateAmount(
                                                  item.localId,
                                                  (amountInt - 1).toDouble(),
                                                ),
                                        icon: const Icon(Icons.remove),
                                      ),
                                      Text(
                                        '$amountInt $unit',
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      IconButton(
                                        tooltip: 'Více',
                                        onPressed: () => vm.updateAmount(
                                          item.localId,
                                          (amountInt + 1).toDouble(),
                                        ),
                                        icon: const Icon(Icons.add),
                                      ),
                                    ] else ...[
                                      SizedBox(
                                        width: 96,
                                        child: TextField(
                                          controller: _amountC(item),
                                          keyboardType:
                                              const TextInputType
                                                  .numberWithOptions(
                                            decimal: true,
                                          ),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            final parsed = double.tryParse(
                                              value.replaceAll(',', '.'),
                                            );

                                            if (parsed != null && parsed > 0) {
                                              vm.updateAmount(
                                                item.localId,
                                                parsed,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        unit,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                    ],
                                    if (estimateLabel.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          estimateLabel,
                                          style:
                                              theme.textTheme.bodySmall?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}