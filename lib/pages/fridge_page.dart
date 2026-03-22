import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diacritic/diacritic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kuchtik/models/user_ingredient.dart';
import 'package:kuchtik/models/ingredient.dart';

//TODO: Ikony
//TODO: Update mnoštví surovin
//

class FridgePage extends StatefulWidget {
  const FridgePage({Key? key}) : super(key: key);

  @override
  State<FridgePage> createState() => _FridgePageState();
}

final supabase = Supabase.instance.client;

class _FridgePageState extends State<FridgePage> {
  List<Ingredient> _allIngredients = [];
  List<UserIngredient> _userIngredients = [];
  Ingredient? _selectedIngredient;
  final TextEditingController _amountController = TextEditingController();
  late String _selectedUnit;
  final _units = ['g', 'ml', 'ks', 'l', 'kg'];

  @override
  void initState() {
    super.initState();
    _loadAllIngredients();
    _loadUserIngredients();
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
        );

    if (!mounted) return;
    setState(() {
      _userIngredients = List<Map<String, dynamic>>.from(
        result,
      ).map((e) => UserIngredient.fromJson(e)).toList();
    });
  }

  List<Ingredient> _filterIngredientNames(String query) {
    if (query.isEmpty) {
      return _allIngredients
          .take(5)
          .toList(); // Return first 5 items if no match
    }
    
    return _allIngredients
        .where(
          (ingredient) => removeDiacritics(
              ingredient.name)
              .toLowerCase()
              .contains(query.toLowerCase()) ||
              ingredient.searchAliases.any(
                (alias) =>
                    removeDiacritics(alias)
                    .toLowerCase()
                    .contains(removeDiacritics(query.toLowerCase())),
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

    final amount = int.parse(amountText);

    try {
      await supabase.schema('public').from('user_pantry').insert({
        'ingredient_id': pending.id,
        'amount': amount,
        'unit': _selectedUnit,
        // if your table needs it:
        // 'user_id': supabase.auth.currentUser!.id,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedIngredient!.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: _selectedUnit,
                            items: _units
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(
                              () => _selectedUnit = v ?? _selectedUnit,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _addIngredient,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Expanded(
            child: IngredientsList(
              items: _userIngredients,
              onRemove: _removeIngredient,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Add new item')));
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
    required this.onRemove,
  }) : _items = items;

  final List<UserIngredient> _items;
  final Future<void> Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _items[index];

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

              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped: ${item.ingredient.name}')),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class AddIngredientWidget extends StatelessWidget {
  const AddIngredientWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'How you wanna add an item?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Add manually')));
              },
              icon: const Icon(Icons.edit),
              label: const Text('Manually'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add via photo of receipt')),
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('Scan'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Take photo')),
                );
              },
              icon: const Icon(Icons.camera),
              label: const Text('Photo'),
            ),
          ],
        ),
         SizedBox(height: 38),
        
      ],
    );
  }
}
