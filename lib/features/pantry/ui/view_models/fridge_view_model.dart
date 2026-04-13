import 'package:diacritic/diacritic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuchtik/core/extensions/string_extension.dart';


import 'package:kuchtik/features/pantry/data/repositories/ingredients_repository.dart';
import 'package:kuchtik/features/pantry/data/repositories/user_pantry_repository.dart';
import 'package:kuchtik/features/pantry/domain/ingredient.dart';
import 'package:kuchtik/features/pantry/domain/pantry_deduction.dart';
import 'package:kuchtik/features/pantry/domain/user_ingredient.dart';
import 'package:kuchtik/core/services/notification_service.dart';
import 'package:kuchtik/core/utils/notification_strings.dart';

final fridgeViewModelProvider =
    AsyncNotifierProvider<FridgeViewModel, List<UserIngredient>>(
  FridgeViewModel.new,
);

class FridgeViewModel extends AsyncNotifier<List<UserIngredient>> {

  UserPantryRepository get _userPantryRepository =>
      ref.read(userPantryRepositoryProvider);

  NotificationService get _notificationService =>
      ref.read(notificationServiceProvider);

  @override
  Future<List<UserIngredient>> build() async {
    return loadUserPantry();
  }

  Future<List<UserIngredient>> loadUserPantry() async {
    return _userPantryRepository.getUserPantry();
  }

  Future<void> addIngredientToPantry({
    required String ingredientId,
    required String ingredientName,
    required double amount,
    required String unit,
    required double price,
    required DateTime expiresAt,
    bool isDiscounted = false,
  }) async {
    state = const AsyncLoading<List<UserIngredient>>();
    try {
      String id = await _userPantryRepository.addIngredientToPantry(
        ingredientId: ingredientId,
        amount: amount,
        unit: unit,
        price: price,
        expiresAt: expiresAt,
        isDiscounted: isDiscounted,
      );

     _notificationService.scheduleNotification(id: id.createNotificationIdFromUuid(), 
     title: NotificationStrings.expiringTitle(price), 
     body: NotificationStrings.expiringBody(ingredientName), 
     scheduledTime: DateTime.now().add(const Duration(seconds: 30)));

      state = AsyncData(await loadUserPantry());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
  
  Future<void> updateUserIngredient(UserIngredient updated) async {
    state = const AsyncLoading<List<UserIngredient>>();
    try {
      await _userPantryRepository.updateUserIngredient(
        id: updated.id,
        amount: updated.amount,
        unit: updated.unit,
        price: updated.price,
        expiresAt: updated.expiresAt,
        isDiscounted: updated.isDiscounted,
      );
      state = AsyncData(await loadUserPantry());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteIngredientFromPantry(String id) async {
    state = const AsyncLoading<List<UserIngredient>>();
    try {
      await _userPantryRepository.deleteIngredientFromPantry(id);

      _notificationService.cancelNotification(id.createNotificationIdFromUuid());

      state = AsyncData(await loadUserPantry());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Applies deductions to the current pantry state without calling Supabase.
  ///
  /// Returns a snapshot of the previous pantry list for rollback.
  List<UserIngredient> applyLocalDeductions(List<PantryDeduction> deductions) {
    final previous = state.asData?.value;
    if (previous == null) {
      throw StateError('Pantry is not loaded yet.');
    }

    if (deductions.isEmpty) {
      return List<UserIngredient>.unmodifiable(previous);
    }

    final next = previous.toList(growable: true);

    // Group deductions by ingredientId + unit
    final Map<String, double> toDeduct = {};
    for (final d in deductions) {
      final amount = d.amount;
      if (amount <= 0) continue;
      final key = '${d.ingredientId}::${d.unit}';
      toDeduct[key] = (toDeduct[key] ?? 0) + amount;
    }

    const epsilon = 1e-9;

    for (final entry in toDeduct.entries) {
      final parts = entry.key.split('::');
      if (parts.length != 2) continue;
      final ingredientId = parts[0];
      final unit = parts[1];
      var remaining = entry.value;
      if (remaining <= 0) continue;

      // Deduct from the soonest-expiring items first.
      final candidates = next
          .where(
            (i) => i.ingredient.id == ingredientId && i.unit.trim() == unit.trim(),
          )
          .toList(growable: false)
        ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));

      for (final item in candidates) {
        if (remaining <= epsilon) break;

        final current = item.amount;
        if (current <= epsilon) continue;

        final deductNow = remaining < current ? remaining : current;
        final updatedAmount = current - deductNow;
        remaining -= deductNow;

        final index = next.indexWhere((x) => x.id == item.id);
        if (index == -1) continue;

        if (updatedAmount <= epsilon) {
          next.removeAt(index);
        } else {
          next[index] = next[index].copyWith(amount: updatedAmount);
        }
      }
    }

    state = AsyncData(List<UserIngredient>.unmodifiable(next));
    return List<UserIngredient>.unmodifiable(previous);
  }

  /// Restores a previously captured pantry snapshot (rollback).
  void restoreLocalPantry(List<UserIngredient> snapshot) {
    state = AsyncData(List<UserIngredient>.unmodifiable(snapshot));
  }

}

List<Ingredient> filterIngredientSuggestions(List<Ingredient> all, String query) {
  if (query.isEmpty) {
    return all.take(5).toList();
  }

  final normalizedQuery = removeDiacritics(query).toLowerCase().trim();

  return all
      .where(
        (ingredient) =>
            removeDiacritics(ingredient.name)
                .toLowerCase()
                .contains(normalizedQuery) ||
            ingredient.searchAliases.any(
              (alias) => removeDiacritics(alias)
                  .toLowerCase()
                  .contains(normalizedQuery),
            ),
      )
      .take(5)
      .toList();
}


final ingredientSuggestionsProvider =
  Provider.family<AsyncValue<List<Ingredient>>, String>((ref, query) {
    final allAsync = ref.watch(allIngredientsProvider);
    return allAsync.whenData((all) => filterIngredientSuggestions(all, query));
  });