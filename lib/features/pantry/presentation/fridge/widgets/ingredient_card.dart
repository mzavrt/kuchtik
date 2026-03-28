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
    this.onConfirm,
    this.confirmLabel = 'Add',
  });

  final String title;
  final TextEditingController amountController;
  final String unit;
  final List<String> units;
  final ValueChanged<String?> onUnitChanged;

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
          ],
        ),
      ),
    );
  }
}
