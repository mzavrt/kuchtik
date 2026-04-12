import 'package:diacritic/diacritic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuchtik/core/extensions/string_extension.dart';


import 'package:kuchtik/features/pantry/data/repositories/ingredients_repository.dart';
import 'package:kuchtik/features/pantry/data/repositories/user_pantry_repository.dart';
import 'package:kuchtik/features/pantry/domain/ingredient.dart';
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