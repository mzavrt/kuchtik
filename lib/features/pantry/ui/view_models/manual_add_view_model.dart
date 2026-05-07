import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/pantry/data/repositories/user_pantry_repository.dart';
import 'package:kuchtik/features/pantry/domain/ingredient.dart';
import 'package:kuchtik/features/pantry/ui/view_models/pantry_view_model.dart';
import 'package:kuchtik/features/pantry/constants/pantry_constants.dart';
import 'package:kuchtik/core/services/notification_service.dart';
import 'package:kuchtik/core/utils/notification_strings.dart';
import 'package:kuchtik/core/extensions/string_extension.dart';
import 'package:kuchtik/features/dashboard/ui/view_models/dashboard_view_model.dart';

final manualAddViewModelProvider =
    NotifierProvider.autoDispose<ManualAddViewModel, ManualAddState>(
  ManualAddViewModel.new,
);

class ManualDraftItem {
  const ManualDraftItem({
    required this.localId,
    required this.ingredient,
    required this.amount,
  });

  final int localId;
  final Ingredient ingredient;

  /// For batch items:
  /// - amount in ingredient.derivedUnit, e.g. 6 ks, 1000 g, 500 ml.
  ///
  /// For per_package items:
  /// - number of pieces/packages, stored as separate user_pantry rows.
  final double amount;

  ManualDraftItem copyWith({
    Ingredient? ingredient,
    double? amount,
  }) {
    return ManualDraftItem(
      localId: localId,
      ingredient: ingredient ?? this.ingredient,
      amount: amount ?? this.amount,
    );
  }
}

class ManualAddState {
  const ManualAddState({
    required this.items,
    required this.isSubmitting,
    required this.errorMessage,
  });

  final List<ManualDraftItem> items;
  final bool isSubmitting;
  final String? errorMessage;

  ManualAddState copyWith({
    List<ManualDraftItem>? items,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ManualAddState(
      items: items ?? this.items,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static ManualAddState initial() => const ManualAddState(
        items: [],
        isSubmitting: false,
        errorMessage: null,
      );
}

class ManualAddViewModel extends Notifier<ManualAddState> {
  int _nextId = 1;

  @override
  ManualAddState build() => ManualAddState.initial();

  double _initialAmountFor(Ingredient ingredient) {
    final configured = ingredient.defaultInputAmount;

    if (configured != null && configured > 0) {
      if (ingredient.derivedUnit == 'ks') {
        final rounded = configured.roundToDouble();
        return rounded < 1 ? 1.0 : rounded;
      }

      return configured;
    }

    return switch (ingredient.derivedUnit) {
      'ks' => 1.0,
      'g' => 100.0,
      'ml' => 100.0,
      _ => 1.0,
    };
  }

  double _sanitizeAmount(Ingredient ingredient, double amount) {
    if (amount.isNaN || amount.isInfinite || amount <= 0) {
      return 1.0;
    }

    if (ingredient.derivedUnit == 'ks') {
      final rounded = amount.roundToDouble();
      return rounded < 1 ? 1.0 : rounded;
    }

    return amount;
  }

  DateTime? _defaultExpirationFor(Ingredient ingredient) {
    final days = ingredient.defaultUseWithinDays;

    if (days == null || days <= 0) {
      return null;
    }

    return DateTime.now().add(Duration(days: days));
  }

  Map<String, Object?> _basePayload({
    required Ingredient ingredient,
    required double amount,
    required String unit,
    required DateTime? expiresAt,
    double? pricePaid,
  }) {
    return {
      'ingredient_id': ingredient.id,
      'amount': amount,
      'unit': unit,
      'price_paid': pricePaid,
      'expires_at': expiresAt?.toIso8601String(),
      'value_per_piece':
          unit == 'ks' ? ingredient.defaultValuePerPiece : null,
    };
  }

  int addIngredient(Ingredient ingredient) {
    final id = _nextId++;

    final item = ManualDraftItem(
      localId: id,
      ingredient: ingredient,
      amount: _initialAmountFor(ingredient),
    );

    state = state.copyWith(
      items: [...state.items, item],
      clearError: true,
    );

    return id;
  }

  void changeIngredient(int id, Ingredient ingredient) {
    final exists = state.items.any((x) => x.localId == id);

    if (!exists) {
      addIngredient(ingredient);
      return;
    }

    state = state.copyWith(
      items: [
        for (final x in state.items)
          if (x.localId == id)
            x.copyWith(
              ingredient: ingredient,
              amount: _initialAmountFor(ingredient),
            )
          else
            x,
      ],
      clearError: true,
    );
  }

  void remove(int id) {
    state = state.copyWith(
      items: state.items.where((x) => x.localId != id).toList(),
      clearError: true,
    );
  }

  void updateAmount(int id, double amount) {
    state = state.copyWith(
      items: [
        for (final x in state.items)
          if (x.localId == id)
            x.copyWith(
              amount: _sanitizeAmount(x.ingredient, amount),
            )
          else
            x,
      ],
      clearError: true,
    );
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;

    if (state.items.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Přidejte alespoň jednu ingredienci.',
      );
      return;
    }

    final notificationService = ref.read(notificationServiceProvider);

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final payload = <Map<String, Object?>>[];

      for (final x in state.items) {
        if (x.amount <= 0) {
          throw StateError('Neplatné množství pro ${x.ingredient.name}.');
        }

        final ingredient = x.ingredient;
        final unit = ingredient.derivedUnit;
        final expiresAt = _defaultExpirationFor(ingredient);

        if (ingredient.isPerPackage) {
          if (unit != 'ks') {
            throw StateError(
              'Ingredience ${ingredient.name} je nastavena jako per_package, '
              'ale výsledná jednotka není ks.',
            );
          }

          final packageCount = x.amount.round();

          if (packageCount <= 0) {
            throw StateError('Neplatný počet kusů pro ${ingredient.name}.');
          }

          if (x.amount != packageCount.toDouble()) {
            throw StateError(
              'Počet kusů musí být celé číslo pro ${ingredient.name}.',
            );
          }

          for (var i = 0; i < packageCount; i++) {
            payload.add(
              _basePayload(
                ingredient: ingredient,
                amount: 1,
                unit: 'ks',
                expiresAt: expiresAt,
                pricePaid: null,
              ),
            );
          }
        } else {
          payload.add(
            _basePayload(
              ingredient: ingredient,
              amount: x.amount,
              unit: unit,
              expiresAt: expiresAt,
              pricePaid: null,
            ),
          );
        }

      }

      final notificationData = await ref
          .read(userPantryRepositoryProvider)
          .addIngredientsToPantry(payload);

        for (final data in notificationData) {
          // If expiration date is null or too far in the future, we skip scheduling notification.
          if (data.expirationAt == null || data.expirationAt!.isAfter(DateTime.now().add(Duration(days: PantryConstants.notificationExpirationDaysFrom)))) continue;


          notificationService.scheduleNotification(
            id: data.id.createNotificationIdFromUuid(),
            title: NotificationStrings.expiringTitle(data.price),
            body: NotificationStrings.expiringBody(data.name),
            scheduledTime: data.expirationAt!,
          );
        }

      ref.invalidate(pantryViewModelProvider);
      ref.invalidate(dashboardViewModelProvider);

      state = ManualAddState.initial();
    } catch (e) {
      final message = switch (e) {
        StateError(:final message) => message,
        _ => e.toString(),
      };

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: message,
      );
    }
  }
}