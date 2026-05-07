import 'package:flutter/material.dart';
import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';
import 'package:kuchtik/features/pantry/ui/widgets/bottom_sheet_update_ingredient.dart';

class IngredientCard extends StatelessWidget {
  const IngredientCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onUpdate,
    this.displayAmount,
    this.displayUnit,
    this.displayText,
    this.stateText,
    this.showExpiration = true,
    this.enableUpdate = true,
    this.onRemoveGroup,
    this.onTapOverride,
    this.trailingIcon,
    this.dense = false,
  });

  static const int _expirationVisibilityThresholdDays = 14;

  final UserIngredient item;
  final Future<dynamic> Function(String) onRemove;
  final Future<dynamic> Function(UserIngredient) onUpdate;

  /// Optional amount shown in the row instead of item.amount.
  final num? displayAmount;

  /// Optional unit shown in the row instead of item.unit.
  final String? displayUnit;

  /// Optional full amount text shown instead of formatted amount + unit.
  ///
  /// Example:
  /// - "100 ml"
  /// - "1 ks + 200 g"
  /// - "2 ks"
  final String? displayText;

  /// Optional state text shown in the subtitle metadata row.
  ///
  /// Example:
  /// - "otevřeno"
  /// - "část otevřena"
  final String? stateText;

  /// Whether expiration should be shown under the row.
  final bool showExpiration;

  /// Whether tapping the card should open the edit bottom sheet.
  final bool enableUpdate;

  /// Optional group delete callback.
  ///
  /// If provided, swiping the visual row deletes all underlying pantry rows
  /// belonging to the same visual ingredient.
  final Future<dynamic> Function()? onRemoveGroup;

  /// Optional custom tap behavior.
  final VoidCallback? onTapOverride;

  /// Optional icon shown after the amount.
  final Widget? trailingIcon;

  /// Used for visually smaller rows, if needed later.
  final bool dense;

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

  Future<void> _openUpdateSheet(BuildContext context) async {
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

    final shouldShowExpiration = showExpiration &&
        daysLeft != null &&
        daysLeft <= _expirationVisibilityThresholdDays;

    final expirationText = !shouldShowExpiration
        ? null
        : daysLeft == 0
            ? 'Vypršelo'
            : 'Zbývá $daysLeft ${_dayWord(daysLeft)}';

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Color? expirationColor = !shouldShowExpiration
        ? null
        : daysLeft! < 3
            ? colorScheme.error
            : daysLeft < 7
                ? colorScheme.tertiary
                : colorScheme.onSurfaceVariant;

    final emoji = (item.ingredient.emoji ?? '').trim();
    final hasEmoji = emoji.isNotEmpty;

    final visibleAmount = displayAmount ?? item.amount;
    final visibleUnit = displayUnit ?? item.unit;

    final amountText =
        displayText ?? _formatAmountWithUnit(visibleAmount, visibleUnit);

    final normalizedStateText = stateText?.trim();
    final hasStateText =
        normalizedStateText != null && normalizedStateText.isNotEmpty;

    final hasSubtitle = hasStateText || shouldShowExpiration;

    final onTap = onTapOverride ??
        (enableUpdate
            ? () async {
                await _openUpdateSheet(context);
              }
            : null);

    final cardMargin = dense
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 6);

    return Dismissible(
      key: ValueKey(
        onRemoveGroup == null ? item.id : 'group-${item.ingredient.id}',
      ),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: cardMargin,
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline,
          color: colorScheme.onError,
        ),
      ),
      confirmDismiss: (_) async {
        return true;
      },
      onDismissed: (_) async {
        if (onRemoveGroup != null) {
          await onRemoveGroup!();
        } else {
          await onRemove(item.id);
        }

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingredience odstraněna.'),
          ),
        );
      },
      child: Card(
        margin: cardMargin,
        child: ListTile(
          dense: dense,
          contentPadding: dense
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 2)
              : const EdgeInsets.fromLTRB(16, 4, 12, 4),
          leading: hasEmoji
              ? Text(
                  emoji,
                  style: dense ? textTheme.titleLarge : textTheme.headlineSmall,
                )
              : const Icon(Icons.kitchen),
          title: Text(
            item.ingredient.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 64,
              maxWidth: 128,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    amountText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 4),
                  trailingIcon!,
                ],
              ],
            ),
          ),
          subtitle: hasSubtitle
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      if (hasStateText) ...[
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        Text(
                          normalizedStateText,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (hasStateText && shouldShowExpiration)
                        Text(
                          '·',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (shouldShowExpiration && expirationText != null)
                        Text(
                          expirationText,
                          style: textTheme.bodySmall?.copyWith(
                            color: expirationColor,
                          ),
                        ),
                    ],
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}