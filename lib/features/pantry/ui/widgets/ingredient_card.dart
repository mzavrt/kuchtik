import 'package:flutter/material.dart';
import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';
import 'package:kuchtik/features/pantry/ui/widgets/bottom_sheet_update_ingredient.dart';

class IngredientCard extends StatelessWidget {
  const IngredientCard({
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