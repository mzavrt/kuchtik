import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kuchtik/features/pantry/domain/ingredient.dart';
import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';
import 'package:kuchtik/features/pantry/ui/image_results_page.dart';
import 'package:kuchtik/features/pantry/ui/manual_add_screen.dart';
import 'package:kuchtik/features/pantry/ui/widgets/expandable_fab.dart';
import 'package:kuchtik/features/pantry/ui/widgets/ingredient_card.dart';
import 'package:kuchtik/features/pantry/ui/view_models/fridge_view_model.dart';


class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  Ingredient? _selectedIngredient;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  late String _selectedUnit;
  DateTime _selectedExpiresAt = DateTime.now().add(const Duration(days: 7));
  final List<String> _units = const ['g', 'ml', 'ks', 'l', 'kg'];

  String _labelForIngredient(Ingredient ingredient) {
    final emoji = (ingredient.emoji ?? '').trim();
    final name = ingredient.name.trim();
    if (emoji.isEmpty) return name;
    if (name.isEmpty) return emoji;
    return '$emoji $name';
  }

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

  Future<XFile?> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      return pickedFile;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  void _addManually() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ManualAddScreen()),
  );
}

  Future<void> _scanReceipt() async {
    final pickedFile = await _pickImage();
    if (!mounted) return;

    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageResultsScreen(
          imageType: 'receipt',
          imageFile: pickedFile,
        ),
      ),
    );
  }

  Future<void> _addFromPhoto() async {
    final pickedFile = await _pickImage();
    if (!mounted) return;

    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageResultsScreen(
          imageType: 'photo',
          imageFile: pickedFile,
        ),
      ),
    );
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
                      title: Text(_labelForIngredient(suggestion)),
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
              title: _labelForIngredient(_selectedIngredient!),
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
      floatingActionButton: ExpandableFab(
        heroTagPrefix: 'pantry_fab',
        actions: [
          ExpandableFabAction(
            icon: Icons.edit,
            label: 'Manually',
            onPressed: _addManually,
          ),
          ExpandableFabAction(
            icon: Icons.receipt_long,
            label: 'Scan',
            onPressed: _scanReceipt,
          ),
          ExpandableFabAction(
            icon: Icons.camera,
            label: 'Photo',
            onPressed: _addFromPhoto,
          ),
        ],
      ),
    );
  }
}

class IngredientsList extends StatelessWidget {
  const IngredientsList({
    super.key,
    required List<UserIngredient> items,
    required this.onRemove,
    required this.onUpdate,
  }) : _items = items;

  final List<UserIngredient> _items;
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
    required this.onUpdate,
  });

  final UserIngredient item;
  final Future<dynamic> Function(String) onRemove;
  final Future<dynamic> Function(UserIngredient) onUpdate;

  @override
  Widget build(BuildContext context) {
    final expiresAt = item.expiresAt?.toLocal();
    final now = DateTime.now();

    int? daysLeft;
    if (expiresAt != null) {
      final diff = expiresAt.difference(now);
      daysLeft = diff.isNegative ? 0 : (diff.inHours / 24).ceil();
    }

    String dayWord(int n) {
      if (n == 1) return 'den';
      if (n >= 2 && n <= 4) return 'dny';
      return 'dní';
    }

    final subtitleText = daysLeft == null
      ? 'Bez expirace'
      : (daysLeft == 0
        ? 'Vypršelo'
        : 'Zbývá $daysLeft ${dayWord(daysLeft)}');

    final colorScheme = Theme.of(context).colorScheme;
    final Color? subtitleColor = daysLeft == null
      ? null
      : (daysLeft < 3
        ? colorScheme.error
        : (daysLeft < 7 ? colorScheme.tertiary : null));

    final emoji = (item.ingredient.emoji ?? '').trim();
    final hasEmoji = emoji.isNotEmpty;
  
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: hasEmoji
              ? Text(
                  emoji,
                  style: Theme.of(context).textTheme.headlineSmall,
                )
              : const Icon(Icons.kitchen),
          title: Row(
            children: [
              Expanded(child: Text(item.ingredient.name)),
              const SizedBox(width: 8),
              Text('${item.amount} ${item.unit}'),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => onRemove(item.id),
          ),
          subtitle: Text(
            subtitleText,
            style: TextStyle(color: subtitleColor),
          ),
          onTap: () async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (sheetContext) {
                return BottomSheetUpdateIngredient(
                  item: item,
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
    required this.onUpdate,
  });

  final UserIngredient item;
  final Future<dynamic> Function(UserIngredient) onUpdate;

  @override
  State<BottomSheetUpdateIngredient> createState() =>
      _BottomSheetUpdateIngredientState();
}

class _BottomSheetUpdateIngredientState
    extends State<BottomSheetUpdateIngredient> {
  late final TextEditingController _amountController;
  late final TextEditingController _priceController;
  late final TextEditingController _actualValuePerPieceController;
  DateTime? _selectedExpiresAt;
  late bool _isDiscounted;

  String _measurementType(Ingredient ingredient) {
    final t = ingredient.measurementType.trim();
    return t.isEmpty ? 'piece' : t;
  }

  String _derivedUnit(Ingredient ingredient) {
    switch (_measurementType(ingredient)) {
      case 'weight':
        return ingredient.estUnit ?? 'g';
      case 'volume':
        return ingredient.estUnit ?? 'ml';
      case 'piece':
      default:
        return 'ks';
    }
  }

  double? _tryParseNullableDouble(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  @override
  void initState() {
    super.initState();
    _selectedExpiresAt = widget.item.expiresAt;
    _isDiscounted = widget.item.isDiscounted;
    _amountController = TextEditingController(
      text: widget.item.amount % 1 == 0
          ? widget.item.amount.toInt().toString()
          : widget.item.amount.toString(),
    );
    _priceController = TextEditingController(
      text: widget.item.pricePaid == null
          ? ''
          : (widget.item.pricePaid! % 1 == 0
              ? widget.item.pricePaid!.toInt().toString()
              : widget.item.pricePaid!.toString()),
    );
    _actualValuePerPieceController = TextEditingController(
      text: widget.item.actualValuePerPiece == null
          ? ''
          : (widget.item.actualValuePerPiece! % 1 == 0
              ? widget.item.actualValuePerPiece!.toInt().toString()
              : widget.item.actualValuePerPiece!.toString()),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _priceController.dispose();
    _actualValuePerPieceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final unit = _derivedUnit(widget.item.ingredient);
    final showActualWeight = unit == 'ks';

    String labelForIngredient(Ingredient ingredient) {
      final emoji = (ingredient.emoji ?? '').trim();
      final name = ingredient.name.trim();
      if (emoji.isEmpty) return name;
      if (name.isEmpty) return emoji;
      return '$emoji $name';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labelForIngredient(widget.item.ingredient),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Množství'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(unit),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cena (Kč) – volitelné',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedExpiresAt == null
                          ? 'Expirace: Bez expirace'
                          : 'Expirace: ${MaterialLocalizations.of(context).formatShortDate(_selectedExpiresAt!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: (_selectedExpiresAt ?? now)
                            .isBefore(now)
                            ? now
                            : (_selectedExpiresAt ?? now),
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 10),
                      );
                      if (picked == null) return;
                      setState(() => _selectedExpiresAt = picked);
                    },
                    child: const Text('Vybrat'),
                  ),
                  if (_selectedExpiresAt != null)
                    TextButton(
                      onPressed: () => setState(() => _selectedExpiresAt = null),
                      child: const Text('Smazat'),
                    ),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _isDiscounted,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _isDiscounted = v);
                },
                title: const Text('Sleva'),
              ),
              if (showActualWeight) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _actualValuePerPieceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Skutečná váha / ks (g) – volitelné',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final newAmount = _tryParseNullableDouble(
                      _amountController.text,
                    );
                    if (newAmount == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Zadejte platné množství.'),
                        ),
                      );
                      return;
                    }

                    final newPrice =
                        _tryParseNullableDouble(_priceController.text);
                    final newActualWeight = showActualWeight
                        ? _tryParseNullableDouble(
                            _actualValuePerPieceController.text,
                          )
                        : null;

                    await widget.onUpdate(
                      widget.item.copyWith(
                        amount: newAmount,
                        pricePaid: newPrice,
                        expiresAt: _selectedExpiresAt,
                        isDiscounted: _isDiscounted,
                        actualValuePerPiece: newActualWeight,
                      ),
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Uložit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
