import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IngredientCard extends StatelessWidget {
  IngredientCard({
    super.key,
    required this.title,
    required this.amountController,
    required this.unit,
    required this.units,
    required this.onUnitChanged,
    this.priceController,
    this.expiresAt,
    this.onExpiresAtChanged,
    this.onConfirm,
    this.confirmLabel = 'Add',
  });

  final String title;
  final TextEditingController amountController;
  final String unit;
  final List<String> units;
  final ValueChanged<String?> onUnitChanged;

  final TextEditingController? priceController;
  final DateTime? expiresAt;
  final ValueChanged<DateTime>? onExpiresAtChanged;

  final VoidCallback? onConfirm; // <-- if null, no button
  final String confirmLabel;
  final decimalFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    final text = newValue.text;
    final ok = RegExp(r'^\d*([.,]\d*)?$').hasMatch(text); // one dot OR comma
    return ok ? newValue : oldValue;
  });

  @override
  Widget build(BuildContext context) {
    final integerOnly = unit == 'ks' || unit == 'g' || unit == 'ml';
    final canPickExpiry = expiresAt != null && onExpiresAtChanged != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: integerOnly
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : [decimalFormatter],
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: unit,
                  items: units
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: onUnitChanged,
                ),
                if (onConfirm != null) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onConfirm,
                    child: Text(confirmLabel),
                  ),
                ],
              ],
            ),
            if (priceController != null || canPickExpiry) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (priceController != null)
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [decimalFormatter],
                        decoration: const InputDecoration(labelText: 'Price'),
                      ),
                    ),
                  if (priceController != null && canPickExpiry)
                    const SizedBox(width: 12),
                  if (canPickExpiry)
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Expires',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () async {
                              final current = expiresAt!;
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
                              onExpiresAtChanged!(picked);
                            },
                            child: Text(
                              MaterialLocalizations.of(context)
                                  .formatShortDate(expiresAt!),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
