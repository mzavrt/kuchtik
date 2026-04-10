import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kuchtik/features/pantry/ui/widgets/ingredient_card.dart';
import 'package:kuchtik/features/pantry/ui/view_models/image_result_screen_view_model.dart';

class ImageResultsScreen extends ConsumerStatefulWidget {
  const ImageResultsScreen({
    super.key,
    required this.imageType,
    required this.imageFile,
  });

  final String imageType;
  final XFile imageFile;
 

  @override
  ConsumerState<ImageResultsScreen> createState() => _ImageResultsScreenState();
}

class _ImageResultsScreenState extends ConsumerState<ImageResultsScreen> {
  List<TextEditingController>? _amountControllers;
  List<TextEditingController>? _priceControllers;
  List<String>? _units;
  List<DateTime>? _expiresAts;

  bool _submitting = false;


  Future<void> _confirmIngredients() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final ingredients = ref.read(imageResultScreenViewModelProvider).value;
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

    return Scaffold(
      appBar: AppBar(title: const Text('Scan results')),
      body: scanState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (ingredientsFromImage) {
          final needsInit =
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

            _amountControllers = List.generate(
              ingredientsFromImage.length,
              (i) => TextEditingController(
                text: ingredientsFromImage[i].amount.toString(),
              ),
            );

            _priceControllers = List.generate(
              ingredientsFromImage.length,
              (i) => TextEditingController(
                text: ingredientsFromImage[i].price.toString(),
              ),
            );

            _units = ingredientsFromImage
                .map((i) => i.unit.isNotEmpty ? i.unit : i.ingredient.defaultUnit)
                .toList();

            _expiresAts = List.generate(
              ingredientsFromImage.length,
              (i) => DateTime.now().add(
                Duration(days: ingredientsFromImage[i].expiresInDays),
              ),
            );
          }

            final amountControllers = _amountControllers!;
            final priceControllers = _priceControllers!;
            final units = _units!;
            final expiresAts = _expiresAts!;

          return ListView.builder(
            itemCount: ingredientsFromImage.length,
            itemBuilder: (context, index) {
              final ingredient = ingredientsFromImage[index];
              return IngredientCard(
                title: ingredient.ingredient.name,
                amountController: amountControllers[index],
                unit: units[index],
                units: const ['g', 'ml', 'ks', 'l', 'kg'],
                onUnitChanged: (v) => setState(
                  () => units[index] = v ?? units[index],
                ),
                priceController: priceControllers[index],
                expiresAt: expiresAts[index],
                onExpiresAtChanged: (d) => setState(() => expiresAts[index] = d),
                onConfirm: null,
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
