import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kuchtik/core/widgets/app_empty_state.dart';

import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';
import 'package:kuchtik/features/pantry/ui/receipt_results_screen.dart';
import 'package:kuchtik/features/pantry/ui/manual_add_screen.dart';
import 'package:kuchtik/features/pantry/ui/view_models/pantry_view_model.dart';
import 'package:kuchtik/features/pantry/ui/widgets/expandable_fab.dart';
import 'package:kuchtik/features/pantry/ui/widgets/ingredients_list.dart';

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  Future<XFile?> _pickImage() async {
    final picker = ImagePicker();

    try {
      return await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  void _addManually() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ManualAddScreen(),
      ),
    );
  }

  Future<void> _scanReceipt() async {
    final pickedFile = await _pickImage();

    if (!mounted) return;

    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nebyl vybrán žádný obrázek.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptResultsScreen(
          imageType: 'receipt',
          imageFile: pickedFile,
        ),
      ),
    );
  }

  Future<void> _removeIngredient(String userIngredientId) async {
    try {
      await ref
          .read(pantryViewModelProvider.notifier)
          .deleteIngredientFromPantry(userIngredientId);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při odstranění ingredience: $e')),
      );
    }
  }

  Future<void> _updateUserIngredient(UserIngredient updated) async {
    try {
      await ref
          .read(pantryViewModelProvider.notifier)
          .updateUserIngredient(updated);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při úpravě ingredience: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantryAsync = ref.watch(pantryViewModelProvider);

    return Scaffold(
      body: pantryAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              icon: Icons.kitchen_outlined,
              title: 'Lednice je zatím prázdná',
              message:
                  'Přidejte první ingredience ručně nebo naskenujte účtenku.',
              primaryLabel: 'Přidat ručně',
              onPrimaryPressed: _addManually,
              secondaryLabel: 'Naskenovat účtenku',
              onSecondaryPressed: _scanReceipt,
            );
          }

          return IngredientsList(
            items: items,
            onRemove: _removeIngredient,
            onUpdate: _updateUserIngredient,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Chyba při načítání lednice: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      floatingActionButton: pantryAsync.maybeWhen(
        data: (items) {
          if (items.isEmpty) return null;

          return ExpandableFab(
            heroTagPrefix: 'pantry_fab',
            actions: [
              ExpandableFabAction(
                icon: Icons.receipt_long,
                label: 'Naskenovat účtenku',
                onPressed: _scanReceipt,
              ),
              ExpandableFabAction(
                icon: Icons.edit,
                label: 'Přidat ručně',
                onPressed: _addManually,
              ),
            ],
          );
        },
        orElse: () => null,
      ),
    );
  }
}


