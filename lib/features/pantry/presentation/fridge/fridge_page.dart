import 'package:flutter/material.dart';

import 'package:diacritic/diacritic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kuchtik/core/data/supabase_client.dart';
import 'package:kuchtik/features/pantry/domain/ingredient.dart';
import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';
import 'package:kuchtik/features/pantry/presentation/fridge/widgets/add_ingredient_sheet.dart';
import 'package:kuchtik/features/pantry/presentation/fridge/widgets/ingredient_card.dart';

//TODO: Ikony
//TODO: Update mnoštví surovin
//

class FridgePage extends StatefulWidget {
  const FridgePage({Key? key}) : super(key: key);

  @override
  State<FridgePage> createState() => _FridgePageState();
}

class _FridgePageState extends State<FridgePage> {
  List<Ingredient> _allIngredients = [];
  List<UserIngredient> _userIngredients = [];
  Ingredient? _selectedIngredient;
  final TextEditingController _amountController = TextEditingController();
  late String _selectedUnit;
  final List<String> _units = const ['g', 'ml', 'ks', 'l', 'kg'];

  @override
  void initState() {
    super.initState();
    _loadAllIngredients();
    _loadUserIngredients();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  //For search suggestions
  Future<void> _loadAllIngredients() async {
    final result = await supabase
        .schema('public')
        .from('ingredients')
        .select('id, name, category, default_unit, search_aliases');

    if (!mounted) return;
    setState(() {
      _allIngredients = List<Map<String, dynamic>>.from(result)
          .map((e) => Ingredient.fromJson(e))
          .where((ingredient) => ingredient.name.isNotEmpty)
          .toList();
    });
  }

  Future<void> _loadUserIngredients() async {
    final result = await supabase
        .schema('public')
        .from('user_pantry')
        .select(
          'id, amount, unit, ingredients (id, name, category, default_unit, search_aliases)',
        )
        .eq('user_id', supabase.auth.currentUser!.id);

    if (!mounted) return;
    setState(() {
      _userIngredients = List<Map<String, dynamic>>.from(result)
          .map((e) => UserIngredient.fromJson(e))
          .toList();
    });
  }

  List<Ingredient> _filterIngredientNames(String query) {
    if (query.isEmpty) {
      return _allIngredients.take(5).toList(); // Return first 5 items if no match
    }

    final normalizedQuery = removeDiacritics(query).toLowerCase();

    return _allIngredients
        .where(
          (ingredient) =>
              removeDiacritics(ingredient.name)
                  .toLowerCase()
                  .contains(normalizedQuery) ||
              ingredient.searchAliases.any(
                (alias) => removeDiacritics(alias)
                    .toLowerCase()
                    .contains(normalizedQuery),
              ),
        )
        .take(5)
        .toList();
  }

  Future<void> _addIngredient() async {
    final pending = _selectedIngredient;
    if (pending == null) return;

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);

    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number for amount.'),
        ),
      );
      return;
    }

    try {
      await supabase.schema('public').from('user_pantry').insert({
        'ingredient_id': pending.id,
        'amount': amount,
        'unit': _selectedUnit
        // 'user_id': auth.uid() default
      });

      if (!mounted) return;
      setState(() => _selectedIngredient = null);
      _loadUserIngredients(); // Refresh the list after adding

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingredient added successfully!')),
      );
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding ingredient: ${e.message}')),
      );
    }
  }

  Future<void> _removeIngredient(String userIngredientId) async {
    try {
      await supabase
          .schema('public')
          .from('user_pantry')
          .delete()
          .eq('id', userIngredientId);
      if (!mounted) return;
      setState(() {
        _userIngredients.removeWhere((e) => e.id == userIngredientId);
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing ingredient: ${e.message}')),
      );
    }
  }

  Future<void> _updateIngredientAmountOrUnit(
    String userIngredientId,
    double? newAmount,
    String? newUnit,
  ) async {
    if (newAmount == null && newUnit == null) return;

    final updateData = <String, dynamic>{};
    if (newAmount != null) updateData['amount'] = newAmount;
    if (newUnit != null) updateData['unit'] = newUnit;

    try {
      await supabase
          .schema('public')
          .from('user_pantry')
          .update(updateData)
          .eq('id', userIngredientId);
      if (!mounted) return;
      setState(() {
        final index = _userIngredients.indexWhere((e) => e.id == userIngredientId);
        if (index != -1) {
          final existing = _userIngredients[index];
          _userIngredients[index] = existing.copyWith(
            amount: newAmount ?? existing.amount,
            unit: newUnit ?? existing.unit,
          );
        }
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating ingredient: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              final suggestions = _filterIngredientNames(controller.text);
              return suggestions.map((suggestion) {
                return ListTile(
                  title: Text(suggestion.name),
                  onTap: () {
                    controller.closeView(suggestion.name);
                    FocusScope.of(context).unfocus();

                    setState(() {
                      _selectedIngredient = suggestion;
                      _amountController.clear();
                      _selectedUnit = suggestion.defaultUnit;
                    });
                  },
                );
              }).toList();
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
              onConfirm: _addIngredient,
              confirmLabel: 'Add',
            ),
          Expanded(
            child: IngredientsList(
              items: _userIngredients,
              units: _units,
              onRemove: _removeIngredient,
              onUpdate: _updateIngredientAmountOrUnit,
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
  final Future<void> Function(String, double?, String?) onUpdate;

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
  final Future<dynamic> Function(String, double?, String?) onUpdate;

  @override
  Widget build(BuildContext context) {
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
          subtitle: Text('${item.amount} ${item.unit}'),
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
  final Future<dynamic> Function(String, double?, String?) onUpdate;

  @override
  State<BottomSheetUpdateIngredient> createState() =>
      _BottomSheetUpdateIngredientState();
}

class _BottomSheetUpdateIngredientState
    extends State<BottomSheetUpdateIngredient> {
  late final TextEditingController _amountController;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.item.unit;
    _amountController = TextEditingController(
      text: widget.item.amount % 1 == 0
          ? widget.item.amount.toInt().toString()
          : widget.item.amount.toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
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
          confirmLabel: 'Uložit',
          onConfirm: () async {
            final text = _amountController.text.trim();
            final newAmount = double.tryParse(text);
            if (newAmount == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Zadejte platné číslo.')),
              );
              return;
            }

            await widget.onUpdate(widget.item.id, newAmount, _selectedUnit);

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}
