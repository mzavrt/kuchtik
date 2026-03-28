import 'package:flutter/material.dart';

import 'package:kuchtik/core/data/supabase_client.dart';
import 'package:kuchtik/features/pantry/domain/photo_ingredient.dart';
import 'package:kuchtik/features/pantry/presentation/fridge/widgets/ingredient_card.dart';

class ImageResultsScreen extends StatefulWidget {
  const ImageResultsScreen({super.key, required this.ingredientsFromImage});
  final List<PhotoIngredient> ingredientsFromImage;

  @override
  State<ImageResultsScreen> createState() => _ImageResultsScreenState();
}

class _ImageResultsScreenState extends State<ImageResultsScreen> {
  late final List<TextEditingController> _controllers;
  late final List<String> _units;

  Future<void> _confirmIngredients() async {
    // Here you would typically send the confirmed ingredients to your backend or update your state
    await supabase.schema("public").from("user_pantry").insert(
      widget.ingredientsFromImage.asMap().entries.map((entry) {
        final index = entry.key;
        final ingredient = entry.value;
        return {
          "ingredient_id": ingredient.ingredient.id,
          "amount": int.tryParse(_controllers[index].text.trim()) ?? 0,
          "unit": _units[index],
        };
      }).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.ingredientsFromImage.length,
      (i) => TextEditingController(
        text: widget.ingredientsFromImage[i].amount.toString(),
      ),
    );
    _units = widget.ingredientsFromImage
        .map((i) => i.unit.isNotEmpty ? i.unit : i.ingredient.defaultUnit)
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan results')),
      body: ListView.builder(
        itemCount: widget.ingredientsFromImage.length,
        itemBuilder: (context, index) {
          final ingredient = widget.ingredientsFromImage[index];

          return IngredientCard(
            title: ingredient.ingredient.name,
            amountController: _controllers[index],
            unit: _units[index],
            units: const ['g', 'ml', 'ks', 'l', 'kg'],
            onUnitChanged: (v) =>
                setState(() => _units[index] = v ?? _units[index]),
            onConfirm: null, // <-- hides the button
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //Confirm and add to fridge
          _confirmIngredients();
        },
      ),
    );
  }
}
