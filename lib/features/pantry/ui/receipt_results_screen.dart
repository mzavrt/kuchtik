import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kuchtik/features/pantry/domain/ingredient.dart';
import 'package:kuchtik/features/pantry/domain/photo_ingredient.dart';
import 'package:kuchtik/features/pantry/ui/view_models/receipt_result_screen_view_model.dart';
import 'package:kuchtik/features/pantry/ui/view_models/pantry_view_model.dart';

class ReceiptResultsScreen extends ConsumerStatefulWidget {
  const ReceiptResultsScreen({
    super.key,
    required this.imageType,
    required this.imageFile,
  });

  final String imageType;
  final XFile imageFile;

  @override
  ConsumerState<ReceiptResultsScreen> createState() =>
      _ReceiptResultsScreenState();
}

class _ReceiptResultsScreenState extends ConsumerState<ReceiptResultsScreen> {
  List<PhotoIngredient>? _items;
  List<TextEditingController>? _amountControllers;
  List<TextEditingController>? _priceControllers;

  bool _submitting = false;

  final TextInputFormatter _decimalFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final text = newValue.text;
    final ok = RegExp(r'^\d*([.,]\d*)?$').hasMatch(text);
    return ok ? newValue : oldValue;
  });

  String _formatDouble(num value) {
    final intValue = value.toInt();

    if (value == intValue) return intValue.toString();

    return value.toString();
  }

  String _labelForIngredient(Ingredient ingredient) {
    final emoji = (ingredient.emoji ?? '').trim();
    final name = ingredient.name.trim();

    if (emoji.isEmpty) return name;
    if (name.isEmpty) return emoji;

    return '$emoji $name';
  }

  double _parseDoubleOrZero(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  double _initialAmountForIngredient(Ingredient ingredient, double current) {
    final unit = ingredient.derivedUnit;

    if (unit == 'ks') {
      final rounded = current.round();
      return (rounded < 1 ? 1 : rounded).toDouble();
    }

    if (current > 0) {
      return current;
    }

    final configured = ingredient.defaultInputAmount;
    if (configured != null && configured > 0) {
      return configured;
    }

    return switch (unit) {
      'g' => 100.0,
      'ml' => 100.0,
      _ => 1.0,
    };
  }

  String _estimateLabelFor({
    required Ingredient ingredient,
    required int amount,
  }) {
    final unit = ingredient.derivedUnit;

    if (unit != 'ks') return '';
    if (!ingredient.hasDefaultPieceValue) return '';

    final estimatedTotal = amount * ingredient.defaultValuePerPiece!;

    return '≈ ${estimatedTotal.toStringAsFixed(0)}${ingredient.defaultValueUnit ?? ''}';
  }

  Future<void> _openSwapIngredientSheet(
    BuildContext context, {
    required int index,
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
                            final items = _items;
                            final amountControllers = _amountControllers;

                            if (items == null ||
                                amountControllers == null ||
                                index < 0 ||
                                index >= items.length) {
                              Navigator.of(sheetContext).pop();
                              return;
                            }

                            final current = items[index];
                            final currentAmount = _parseDoubleOrZero(
                              amountControllers[index].text,
                            );

                            final nextAmount = _initialAmountForIngredient(
                              suggestion,
                              currentAmount,
                            );

                            setState(() {
                              items[index] = current.copyWith(
                                ingredient: suggestion,
                                unit: suggestion.derivedUnit,
                                amount: nextAmount,
                              );

                              amountControllers[index].text =
                                  _formatDouble(nextAmount);
                            });

                            controller.closeView(suggestion.name);
                            Navigator.of(sheetContext).pop();
                          },
                        );
                      }).toList();
                    },
                    loading: () => const [ListTile(title: Text('Načítám...'))],
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

  Future<void> _confirmIngredients() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final ingredients =
          _items?.cast<PhotoIngredient>() ??
          ref.read(receiptResultScreenViewModelProvider).value;

      if (ingredients == null || ingredients.isEmpty) return;

      final amountControllers = _amountControllers;
      final priceControllers = _priceControllers;

      if (amountControllers == null || priceControllers == null) return;

      final amountTexts = amountControllers
          .map((c) => c.text)
          .toList(growable: false);

      final priceTexts = priceControllers
          .map((c) => c.text)
          .toList(growable: false);

      await ref
          .read(receiptResultScreenViewModelProvider.notifier)
          .addIngredientsFromLLMResult(
            ingredients: ingredients,
            amountTexts: amountTexts,
            priceTexts: priceTexts,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding to pantry: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref
          .read(receiptResultScreenViewModelProvider.notifier)
          .sendImagetoLLM(
            imageType: widget.imageType,
            imageFile: widget.imageFile,
          );
    });
  }

  @override
  void dispose() {
    final amountControllers = _amountControllers;
    if (amountControllers != null) {
      for (final c in amountControllers) {
        c.dispose();
      }
    }

    final priceControllers = _priceControllers;
    if (priceControllers != null) {
      for (final c in priceControllers) {
        c.dispose();
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(receiptResultScreenViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Výsledky rozpoznávání')),
      body: scanState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (ingredientsFromImage) {
          final localItems = _items?.cast<PhotoIngredient>();
          final currentLength = localItems?.length;

          final needsInit =
              localItems == null ||
              currentLength != ingredientsFromImage.length ||
              _amountControllers == null ||
              _amountControllers!.length != ingredientsFromImage.length ||
              _priceControllers == null ||
              _priceControllers!.length != ingredientsFromImage.length;

          if (needsInit) {
            _amountControllers?.forEach((c) => c.dispose());
            _priceControllers?.forEach((c) => c.dispose());

            _items = ingredientsFromImage.map((item) {
              final unit = item.ingredient.derivedUnit;
              final nextAmount = _initialAmountForIngredient(
                item.ingredient,
                item.amount,
              );

              return item.copyWith(
                unit: unit,
                amount: nextAmount,
              );
            }).toList(growable: true);

            _amountControllers = List.generate(
              _items!.length,
              (i) => TextEditingController(
                text: _formatDouble(_items![i].amount),
              ),
            );

            _priceControllers = List.generate(
              _items!.length,
              (i) => TextEditingController(
                text: _formatDouble(_items![i].price),
              ),
            );
          }

          final items = _items!.cast<PhotoIngredient>();
          final amountControllers = _amountControllers!;
          final priceControllers = _priceControllers!;

          return items.isEmpty
              ? const Center(child: Text('Nic nebylo rozpoznáno.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final ingredient = item.ingredient;
                    final unit = ingredient.derivedUnit;
                    final usesStepper = unit == 'ks';

                    final amountText = amountControllers[index].text;
                    final amountParsed = _parseDoubleOrZero(amountText);
                    final amountInt = amountParsed.round() < 1
                        ? 1
                        : amountParsed.round();

                    final estimateLabel = _estimateLabelFor(
                      ingredient: ingredient,
                      amount: amountInt,
                    );

                    return Dismissible(
                      key: ValueKey('scan-$index-${ingredient.id}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        setState(() {
                          _items!.removeAt(index);
                          _amountControllers!.removeAt(index).dispose();
                          _priceControllers!.removeAt(index).dispose();
                        });
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _labelForIngredient(ingredient),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Upravit ingredienci',
                                    onPressed: () => _openSwapIngredientSheet(
                                      context,
                                      index: index,
                                    ),
                                    icon: const Icon(Icons.edit),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (usesStepper) ...[
                                    IconButton(
                                      tooltip: 'Méně',
                                      onPressed: amountInt <= 1
                                          ? null
                                          : () {
                                              setState(() {
                                                amountControllers[index].text =
                                                    (amountInt - 1).toString();

                                                items[index] =
                                                    items[index].copyWith(
                                                  amount:
                                                      (amountInt - 1).toDouble(),
                                                );
                                              });
                                            },
                                      icon: const Icon(Icons.remove),
                                    ),
                                    Text(
                                      '$amountInt $unit',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    IconButton(
                                      tooltip: 'Více',
                                      onPressed: () {
                                        setState(() {
                                          amountControllers[index].text =
                                              (amountInt + 1).toString();

                                          items[index] =
                                              items[index].copyWith(
                                            amount: (amountInt + 1).toDouble(),
                                          );
                                        });
                                      },
                                      icon: const Icon(Icons.add),
                                    ),
                                  ] else ...[
                                    SizedBox(
                                      width: 96,
                                      child: TextField(
                                        controller: amountControllers[index],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        inputFormatters: [_decimalFormatter],
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          final parsed =
                                              _parseDoubleOrZero(value);

                                          if (parsed > 0) {
                                            items[index] =
                                                items[index].copyWith(
                                              amount: parsed,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
                              const SizedBox(height: 12),
                              TextField(
                                controller: priceControllers[index],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [_decimalFormatter],
                                decoration: const InputDecoration(
                                  labelText: 'Cena',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (_submitting || scanState.isLoading)
            ? null
            : _confirmIngredients,
        child: _submitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check),
      ),
    );
  }
}