import 'package:flutter/material.dart';
import 'package:kuchtik/features/pantry/domain/ingredient.dart';
import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';

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

  String _measurementType(Ingredient ingredient) {
    final type = ingredient.measurementType.trim();
    return type.isEmpty ? 'piece' : type;
  }

  String _derivedUnit(Ingredient ingredient) {
    return ingredient.derivedUnit;
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

    _amountController = TextEditingController(
      text: _formatDouble(widget.item.amount),
    );

    _priceController = TextEditingController(
      text: widget.item.pricePaid == null
          ? ''
          : _formatDouble(widget.item.pricePaid!),
    );

    _actualValuePerPieceController = TextEditingController(
      text: widget.item.valuePerPiece == null
          ? ''
          : _formatDouble(widget.item.valuePerPiece!),
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
    final showActualValue = unit == 'ks';

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
          
              if (showActualValue) ...[
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

                    final newActualValuePerPiece = showActualValue
                        ? _tryParseNullableDouble(
                            _actualValuePerPieceController.text,
                          )
                        : null;

                    await widget.onUpdate(
                      widget.item.copyWith(
                        amount: newAmount,
                        pricePaid: newPrice,
                        expiresAt: _selectedExpiresAt,                    
                        valuePerPiece: newActualValuePerPiece,
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