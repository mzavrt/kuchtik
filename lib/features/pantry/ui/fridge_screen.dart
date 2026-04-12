import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuchtik/features/pantry/domain/ingredient.dart';
import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';
import 'package:kuchtik/features/pantry/ui/widgets/add_ingredient_sheet.dart';
import 'package:kuchtik/features/pantry/ui/widgets/ingredient_card.dart';
import 'package:kuchtik/features/pantry/ui/view_models/fridge_view_model.dart';

//TODO: Ikony
//TODO: Update mnoštví surovin
//

class FridgeScreen extends ConsumerStatefulWidget {
  const FridgeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends ConsumerState<FridgeScreen> {
  Ingredient? _selectedIngredient;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  late String _selectedUnit;
  DateTime _selectedExpiresAt = DateTime.now().add(const Duration(days: 7));
  final List<String> _units = const ['g', 'ml', 'ks', 'l', 'kg'];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _addIngredient() async {
    final pending = _selectedIngredient;
    if (pending == null) return;

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final normalizedAmountText = amountText.replaceAll(',', '.');
    final amount = double.tryParse(normalizedAmountText);

    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number for amount.'),
        ),
      );
      return;
    }

    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a price.')),
      );
      return;
    }

    final normalizedPrice = priceText.replaceAll(',', '.');
    final price = double.tryParse(normalizedPrice);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number for price.')),
      );
      return;
    }

    try {
      await ref
          .read(fridgeViewModelProvider.notifier)
          .addIngredientToPantry(
            ingredientId: pending.id,
            ingredientName: pending.name,
            amount: amount,
            unit: _selectedUnit,
            price: price,
            expiresAt: _selectedExpiresAt,
            isDiscounted: false,
          );

      if (!mounted) return;
      setState(() => _selectedIngredient = null);

      _amountController.clear();
      _priceController.clear();
      _selectedExpiresAt = DateTime.now().add(const Duration(days: 7));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingredient added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding ingredient: $e')),
      );
    }
  }

  Future<void> _removeIngredient(String userIngredientId) async {
    try {
      await ref
          .read(fridgeViewModelProvider.notifier)
          .deleteIngredientFromPantry(userIngredientId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing ingredient: $e')),
      );
    }
  }

  Future<void> _updateUserIngredient(UserIngredient updated) async {
    try {
      await ref
          .read(fridgeViewModelProvider.notifier)
          .updateUserIngredient(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating ingredient: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantryAsync = ref.watch(fridgeViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Moje lednice')),
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
              final ingredientsAsync =
                  ref.watch(ingredientSuggestionsProvider(controller.text));

              return ingredientsAsync.when(
                data: (suggestions) {
                  return suggestions.map((suggestion) {
                    return ListTile(
                      title: Text(suggestion.name),
                      onTap: () {
                        controller.closeView(suggestion.name);
                        FocusScope.of(context).unfocus();

                        setState(() {
                          _selectedIngredient = suggestion;
                          _amountController.clear();
                          _priceController.clear();
                          _selectedUnit = suggestion.defaultUnit;
                          _selectedExpiresAt =
                              DateTime.now().add(const Duration(days: 7));
                        });
                      },
                    );
                  }).toList();
                },
                loading: () => const [
                  ListTile(
                    title: Text('Načítám ingredience...'),
                  ),
                ],
                error: (error, _) => [
                  ListTile(
                    title: Text('Chyba při načítání: $error'),
                  ),
                ],
              );
            },
          ),
          if (_selectedIngredient != null)
            IngredientCard(
              title: _selectedIngredient!.name,
              amountController: _amountController,
              unit: _selectedUnit,
              units: _units,
              onUnitChanged: (newUnit) {
                if (newUnit != null) {
                  setState(() => _selectedUnit = newUnit);
                }
              },
              priceController: _priceController,
              expiresAt: _selectedExpiresAt,
              onExpiresAtChanged: (d) => setState(() => _selectedExpiresAt = d),
              onConfirm: _addIngredient,
              confirmLabel: 'Add',
            ),
          Expanded(
            child: pantryAsync.when(
              data: (items) => IngredientsList(
                items: items,
                units: _units,
                onRemove: _removeIngredient,
                onUpdate: _updateUserIngredient,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Chyba při načítání lednice: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Add new item')));
          showModalBottomSheet(
            context: context,
            useSafeArea: false,
            isScrollControlled: true,
            builder: (context) {
              final bottomInset = MediaQuery.of(context).viewInsets.bottom;
              return Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: SafeArea(
                  minimum: const EdgeInsets.all(16),
                  child: const AddIngredientWidget(),
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class IngredientsList extends StatelessWidget {
  const IngredientsList({
    super.key,
    required List<UserIngredient> items,
    required this.units,
    required this.onRemove,
    required this.onUpdate,
  }) : _items = items;

  final List<UserIngredient> _items;
  final List<String> units;
  final Future<void> Function(String) onRemove;
  final Future<void> Function(UserIngredient) onUpdate;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _items[index];

        return ViewIngredientCard(
          item: item,
          onRemove: onRemove,
          units: units,
          onUpdate: onUpdate,
        );
      },
    );
  }
}

class ViewIngredientCard extends StatelessWidget {
  const ViewIngredientCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.units,
    required this.onUpdate,
  });

  final UserIngredient item;
  final Future<dynamic> Function(String) onRemove;
  final List<String> units;
  final Future<dynamic> Function(UserIngredient) onUpdate;

  @override
  Widget build(BuildContext context) {
    final dateText = MaterialLocalizations.of(context)
        .formatShortDate(item.expiresAt.toLocal());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: const Icon(Icons.kitchen),
          title: Text(item.ingredient.name),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => onRemove(item.id),
          ),
          subtitle: Text(
            '${item.amount} ${item.unit}  •  ${item.price}  •  $dateText',
          ),
          onTap: () async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (sheetContext) {
                return BottomSheetUpdateIngredient(
                  item: item,
                  units: units,
                  onUpdate: onUpdate,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class BottomSheetUpdateIngredient extends StatefulWidget {
  const BottomSheetUpdateIngredient({
    super.key,
    required this.item,
    required this.units,
    required this.onUpdate,
  });

  final UserIngredient item;
  final List<String> units;
  final Future<dynamic> Function(UserIngredient) onUpdate;

  @override
  State<BottomSheetUpdateIngredient> createState() =>
      _BottomSheetUpdateIngredientState();
}

class _BottomSheetUpdateIngredientState
    extends State<BottomSheetUpdateIngredient> {
  late final TextEditingController _amountController;
  late final TextEditingController _priceController;
  late String _selectedUnit;
  late DateTime _selectedExpiresAt;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.item.unit;
    _selectedExpiresAt = widget.item.expiresAt;
    _amountController = TextEditingController(
      text: widget.item.amount % 1 == 0
          ? widget.item.amount.toInt().toString()
          : widget.item.amount.toString(),
    );
    _priceController = TextEditingController(
      text: widget.item.price % 1 == 0
          ? widget.item.price.toInt().toString()
          : widget.item.price.toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: IngredientCard(
          title: widget.item.ingredient.name,
          amountController: _amountController,
          unit: _selectedUnit,
          units: widget.units,
          onUnitChanged: (newUnit) {
            if (newUnit == null) return;
            setState(() => _selectedUnit = newUnit);
          },
          priceController: _priceController,
          expiresAt: _selectedExpiresAt,
          onExpiresAtChanged: (d) => setState(() => _selectedExpiresAt = d),
          confirmLabel: 'Uložit',
          onConfirm: () async {
            final text = _amountController.text.trim();
            final normalizedText = text.replaceAll(',', '.');
            final newAmount = double.tryParse(normalizedText);
            if (newAmount == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Zadejte platné číslo.')),
              );
              return;
            }

            final rawPrice = _priceController.text.trim();
            final normalizedPrice = rawPrice.replaceAll(',', '.');
            final newPrice = double.tryParse(normalizedPrice);
            if (newPrice == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Zadejte platnou cenu.')),
              );
              return;
            }

            await widget.onUpdate(
              widget.item.copyWith(
                amount: newAmount,
                unit: _selectedUnit,
                price: newPrice,
                expiresAt: _selectedExpiresAt,
              ),
            );

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}
