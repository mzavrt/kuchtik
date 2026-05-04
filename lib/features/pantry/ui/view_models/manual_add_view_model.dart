import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuchtik/features/pantry/data/repositories/user_pantry_repository.dart';
import 'package:kuchtik/features/pantry/domain/ingredient.dart';
import 'package:kuchtik/features/pantry/ui/view_models/pantry_view_model.dart';

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

  double _initialAmountFor(Ingredient ingredient) {
  final est = ingredient.defaultValuePerPiece;

  if (est != null && est > 0 && ingredient.measurementType != 'piece') {
    return est;
  }

  return 1.0;
}

  @override
  ManualAddState build() => ManualAddState.initial();

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
    if (amount.isNaN || amount.isInfinite) return;
    final rounded = amount.roundToDouble();
    final nextAmount = rounded < 1 ? 1.0 : rounded;

    state = state.copyWith(
      items: [
        for (final x in state.items)
          if (x.localId == id) x.copyWith(amount: nextAmount) else x,
      ],
      clearError: true,
    );
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;
    if (state.items.isEmpty) {
      state = state.copyWith(errorMessage: 'Přidejte alespoň jednu ingredienci.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final payload = <Map<String, Object?>>[];

      for (final x in state.items) {
        if (x.amount <= 0) {
          throw StateError('Neplatné množství pro ${x.ingredient.name}.');
        }

        payload.add({
          'ingredient_id': x.ingredient.id,
          'amount': x.amount,
          'unit': x.ingredient.derivedUnit,
          'price_paid': null,
          'expires_at': x.
          ingredient.defaultUseWithinDays != null
              ? DateTime.now().add(
                  Duration(days: x.ingredient.defaultUseWithinDays!),
                ).toIso8601String()
              : null,
          'actual_value_per_piece': null,
        });
      }

      await ref.read(userPantryRepositoryProvider).addIngredientsToPantry(payload);

      ref.invalidate(pantryViewModelProvider);
      state = ManualAddState.initial();
   } catch (e) {
  final message = switch (e) {
    StateError(:final message) => message,
    _ => e.toString(),
  };
  state = state.copyWith(isSubmitting: false, errorMessage: message);
}
  }
}
