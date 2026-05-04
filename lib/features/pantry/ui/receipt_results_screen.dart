import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kuchtik/features/pantry/domain/ingredient.dart';
import 'package:kuchtik/features/pantry/domain/photo_ingredient.dart';
import 'package:kuchtik/features/pantry/ui/view_models/image_result_screen_view_model.dart';
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
  ConsumerState<ReceiptResultsScreen> createState() => _ReceiptResultsScreenState();
}

class _ReceiptResultsScreenState extends ConsumerState<ReceiptResultsScreen> {
  List<PhotoIngredient>? _items;
  List<TextEditingController>? _amountControllers;
  List<TextEditingController>? _priceControllers;
  List<String>? _units;
  List<DateTime>? _expiresAts;

  bool _submitting = false;

  final TextInputFormatter _decimalFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
    final text = newValue.text;
    final ok = RegExp(r'^\d*([.,]\d*)?$').hasMatch(text); // one dot OR comma
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
                            final units = _units;
                            final expiresAts = _expiresAts;

                            if (items == null ||
                                amountControllers == null ||
                                units == null ||
                                expiresAts == null ||
                                index < 0 ||
                                index >= items.length) {
                              Navigator.of(sheetContext).pop();
                              return;
                            }

                            final current = items[index] as dynamic;
                            if (current is! PhotoIngredient) {
                              Navigator.of(sheetContext).pop();
                              return;
                            }

                            setState(() {
                              items[index] = current.copyWith(
                                ingredient: suggestion,
                              );

                              // Keep the user's entered amount, but if switching to pieces
                              // make sure it's an integer >= 1.
                              final amount = _parseDoubleOrZero(
                                amountControllers[index].text,
                              );
                              final nextAmount = suggestion.measurementType == 'piece'
                                  ? (amount.round() < 1 ? 1 : amount.round())
                                      .toString()
                                  : (amount <= 0 ? '1' : _formatDouble(amount));
                              amountControllers[index].text = nextAmount;

                              units[index] = suggestion.derivedUnit;

                              final days = suggestion.defaultUseWithinDays;
                              if (days != null) {
                                expiresAts[index] =
                                    DateTime.now().add(Duration(days: days));
                              }
                            });

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


  Future<void> _confirmIngredients() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final ingredients = _items?.cast<PhotoIngredient>() ??
          ref.read(imageResultScreenViewModelProvider).value;
      if (ingredients == null || ingredients.isEmpty) return;

      final amountControllers = _amountControllers;
      final priceControllers = _priceControllers;
      final units = _units;
      final expiresAts = _expiresAts;
      if (amountControllers == null || priceControllers == null) return;
      if (units == null || expiresAts == null) return;

      final amountTexts =
          amountControllers.map((c) => c.text).toList(growable: false);
      final priceTexts =
          priceControllers.map((c) => c.text).toList(growable: false);

      await ref
          .read(imageResultScreenViewModelProvider.notifier)
          .addIngredientsFromLLMResult(
        ingredients: ingredients,
        amountTexts: amountTexts,
        units: units,
        priceTexts: priceTexts,
        expiresAts: expiresAts,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // back to fridge
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to pantry: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }

  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref
          .read(imageResultScreenViewModelProvider.notifier)
          .sendImagetoLLM(imageType: widget.imageType, imageFile: widget.imageFile);
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
    final scanState = ref.watch(imageResultScreenViewModelProvider);
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
              _priceControllers!.length != ingredientsFromImage.length ||
              _units == null ||
              _units!.length != ingredientsFromImage.length ||
              _expiresAts == null ||
              _expiresAts!.length != ingredientsFromImage.length;

          if (needsInit) {
            _amountControllers?.forEach((c) => c.dispose());
            _priceControllers?.forEach((c) => c.dispose());

            _items = ingredientsFromImage.toList(growable: true);

            _amountControllers = List.generate(
              ingredientsFromImage.length,
              (i) => TextEditingController(
                text: _formatDouble(ingredientsFromImage[i].amount),
              ),
            );

            _priceControllers = List.generate(
              ingredientsFromImage.length,
              (i) => TextEditingController(
                text: _formatDouble(ingredientsFromImage[i].price),
              ),
            );

            _units = ingredientsFromImage
                .map((i) => i.unit.isNotEmpty ? i.unit : i.ingredient.derivedUnit)
                .toList();

            _expiresAts = List.generate(
              ingredientsFromImage.length,
              (i) => DateTime.now().add(
                Duration(days: ingredientsFromImage[i].expiresInDays),
              ),
            );
          }

          final items = _items!.cast<PhotoIngredient>();
          final amountControllers = _amountControllers!;
          final priceControllers = _priceControllers!;
          final units = _units!;
          final expiresAts = _expiresAts!;

          return items.isEmpty
              ? const Center(child: Text('Nic nebylo rozpoznáno.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final measurementType =
                        item.ingredient.measurementType.trim().isEmpty
                            ? 'piece'
                            : item.ingredient.measurementType.trim();
                    final isPiece = measurementType == 'piece';

                    // Keep units in sync with piece rows.
                    if (isPiece && units[index] != 'ks') {
                      units[index] = 'ks';
                    }

                    final unit = units[index];
                    final amountText = amountControllers[index].text;
                    final amountParsed = _parseDoubleOrZero(amountText);
                    final amountInt = amountParsed.round() < 1
                        ? 1
                        : amountParsed.round();

                    final hasEstimate = isPiece &&
                        item.ingredient.defaultValuePerPiece != null &&
                        item.ingredient.defaultValuePerPiece! > 0;
                    final estimatedTotal = hasEstimate
                        ? amountInt * item.ingredient.defaultValuePerPiece!
                        : null;

                    return Dismissible(
                      key: ValueKey('scan-$index-${item.ingredient.id}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        setState(() {
                          _items!.removeAt(index);
                          _amountControllers!.removeAt(index).dispose();
                          _priceControllers!.removeAt(index).dispose();
                          _units!.removeAt(index);
                          _expiresAts!.removeAt(index);
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
                                      _labelForIngredient(item.ingredient),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Upravit ingredienci',
                                    onPressed: () =>
                                        _openSwapIngredientSheet(context, index: index),
                                    icon: const Icon(Icons.edit),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (isPiece) ...[
                                    IconButton(
                                      tooltip: 'Méně',
                                      onPressed: amountInt <= 1
                                          ? null
                                          : () {
                                              setState(() {
                                                amountControllers[index].text =
                                                    (amountInt - 1).toString();
                                              });
                                            },
                                      icon: const Icon(Icons.remove),
                                    ),
                                    Text(
                                      '$amountInt ${item.ingredient.derivedUnit}',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    IconButton(
                                      tooltip: 'Více',
                                      onPressed: () {
                                        setState(() {
                                          amountControllers[index].text =
                                              (amountInt + 1).toString();
                                        });
                                      },
                                      icon: const Icon(Icons.add),
                                    ),
                                  ] else ...[
                                    SizedBox(
                                      width: 96,
                                      child: TextField(
                                        controller: amountControllers[index],
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        inputFormatters: [_decimalFormatter],
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    DropdownButton<String>(
                                      value: unit,
                                      items: const ['g', 'ml', 'ks', 'l', 'kg']
                                          .map(
                                            (u) => DropdownMenuItem(
                                              value: u,
                                              child: Text(u),
                                            ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (v) => setState(
                                        () => units[index] = v ?? units[index],
                                      ),
                                    ),
                                  ],
                                  if (hasEstimate) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '≈ ${estimatedTotal!.toStringAsFixed(0)}${item.ingredient.defaultValueUnit ?? ''}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: priceControllers[index],
                                      keyboardType: const TextInputType
                                          .numberWithOptions(decimal: true),
                                      inputFormatters: [_decimalFormatter],
                                      decoration: const InputDecoration(
                                        labelText: 'Cena',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Expiruje',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: () async {
                                            final current = expiresAts[index];
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: current,
                                              firstDate: DateTime.now().subtract(
                                                const Duration(days: 365 * 2),
                                              ),
                                              lastDate: DateTime.now().add(
                                                const Duration(days: 365 * 10),
                                              ),
                                            );
                                            if (picked == null) return;
                                            setState(() =>
                                                expiresAts[index] = picked);
                                          },
                                          child: Text(
                                            MaterialLocalizations.of(context)
                                                .formatShortDate(expiresAts[index]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
        onPressed: (_submitting || scanState.isLoading) ? null : _confirmIngredients,
        child: _submitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check),
      ),
    );
    
  }
}
