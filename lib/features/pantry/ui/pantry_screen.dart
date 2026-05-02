import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kuchtik/core/widgets/app_empty_state.dart';
import 'package:kuchtik/features/pantry/domain/ingredient.dart';
import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';
import 'package:kuchtik/features/pantry/ui/image_results_page.dart';
import 'package:kuchtik/features/pantry/ui/manual_add_screen.dart';
import 'package:kuchtik/features/pantry/ui/view_models/fridge_view_model.dart';
import 'package:kuchtik/features/pantry/ui/widgets/expandable_fab.dart';

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
        builder: (_) => ImageResultsScreen(
          imageType: 'receipt',
          imageFile: pickedFile,
        ),
      ),
    );
  }

  Future<void> _removeIngredient(String userIngredientId) async {
    try {
      await ref
          .read(fridgeViewModelProvider.notifier)
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
          .read(fridgeViewModelProvider.notifier)
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
    final pantryAsync = ref.watch(fridgeViewModelProvider);

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
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  static const int _expirationVisibilityThresholdDays = 14;

  final UserIngredient item;
  final Future<dynamic> Function(String) onRemove;
  final Future<dynamic> Function(UserIngredient) onUpdate;

  String _formatAmount(num value) {
    final intValue = value.toInt();

    if (value == intValue) return intValue.toString();

    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _formatAmountWithUnit(num amount, String unit) {
    final normalizedUnit = unit.trim().toLowerCase();

    if (normalizedUnit == 'g' && amount >= 1000 && amount % 1000 == 0) {
      return '${_formatAmount(amount / 1000)} kg';
    }

    if (normalizedUnit == 'ml' && amount >= 1000 && amount % 1000 == 0) {
      return '${_formatAmount(amount / 1000)} l';
    }

    return '${_formatAmount(amount)} $unit';
  }

  String _dayWord(int n) {
    if (n == 1) return 'den';
    if (n >= 2 && n <= 4) return 'dny';
    return 'dní';
  }

  @override
  Widget build(BuildContext context) {
    final expiresAt = item.expiresAt?.toLocal();
    final now = DateTime.now();

    int? daysLeft;

    if (expiresAt != null) {
      final diff = expiresAt.difference(now);
      daysLeft = diff.isNegative ? 0 : (diff.inHours / 24).ceil();
    }

    final shouldShowExpiration =
        daysLeft != null && daysLeft <= _expirationVisibilityThresholdDays;

    final subtitleText = !shouldShowExpiration
        ? ''
        : daysLeft == 0
            ? 'Vypršelo'
            : 'Zbývá $daysLeft ${_dayWord(daysLeft)}';

    final colorScheme = Theme.of(context).colorScheme;

    final Color? subtitleColor = !shouldShowExpiration
        ? null
        : daysLeft! < 3
            ? colorScheme.error
            : daysLeft < 7
                ? colorScheme.tertiary
                : null;

    final emoji = (item.ingredient.emoji ?? '').trim();
    final hasEmoji = emoji.isNotEmpty;

    return Dismissible(
  key: ValueKey(item.id),
  direction: DismissDirection.endToStart,
  background: Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 24),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.error,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      Icons.delete_outline,
      color: Theme.of(context).colorScheme.onError,
    ),
  ),
  confirmDismiss: (_) async {
    return true;
  },
  onDismissed: (_) async {
    await onRemove(item.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ingredience odstraněna.'),
      ),
    );
  },
  child: Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ListTile(
      leading: hasEmoji
          ? Text(
              emoji,
              style: Theme.of(context).textTheme.headlineSmall,
            )
          : const Icon(Icons.kitchen),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.ingredient.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatAmountWithUnit(item.amount, item.unit),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
      subtitle: SizedBox(
        height: 20,
        child: shouldShowExpiration
            ? Text(
                subtitleText,
                style: TextStyle(color: subtitleColor),
              )
            : null,
      ),
      onTap: () async {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
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
    final type = ingredient.measurementType.trim();
    return type.isEmpty ? 'piece' : type;
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

  String _formatDouble(num value) {
    final intValue = value.toInt();

    if (value == intValue) return intValue.toString();

    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

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

    _selectedExpiresAt = widget.item.expiresAt;
    _isDiscounted = widget.item.isDiscounted;

    _amountController = TextEditingController(
      text: _formatDouble(widget.item.amount),
    );

    _priceController = TextEditingController(
      text: widget.item.pricePaid == null
          ? ''
          : _formatDouble(widget.item.pricePaid!),
    );

    _actualValuePerPieceController = TextEditingController(
      text: widget.item.actualValuePerPiece == null
          ? ''
          : _formatDouble(widget.item.actualValuePerPiece!),
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

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _labelForIngredient(widget.item.ingredient),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Množství',
                      ),
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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

                      final initialDate =
                          (_selectedExpiresAt ?? now).isBefore(now)
                              ? now
                              : (_selectedExpiresAt ?? now);

                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 10),
                      );

                      if (picked == null) return;

                      setState(() {
                        _selectedExpiresAt = picked;
                      });
                    },
                    child: const Text('Vybrat'),
                  ),
                  if (_selectedExpiresAt != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedExpiresAt = null;
                        });
                      },
                      child: const Text('Smazat'),
                    ),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _isDiscounted,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _isDiscounted = value;
                  });
                },
                title: const Text('Sleva'),
              ),
              if (showActualWeight) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _actualValuePerPieceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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

                    if (newAmount == null || newAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Zadejte platné množství.'),
                        ),
                      );
                      return;
                    }

                    final newPrice = _tryParseNullableDouble(
                      _priceController.text,
                    );

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