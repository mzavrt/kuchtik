import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kuchtik/core/extensions/string_extension.dart';

import 'package:kuchtik/features/pantry/data/repositories/image_scan_repository.dart';
import 'package:kuchtik/features/pantry/domain/photo_ingredient.dart';
import 'package:kuchtik/features/pantry/data/repositories/user_pantry_repository.dart';
import 'package:kuchtik/features/pantry/ui/view_models/fridge_view_model.dart';
import 'package:kuchtik/core/services/notification_service.dart';
import 'package:kuchtik/core/utils/notification_strings.dart';



final imageResultScreenViewModelProvider =
    AsyncNotifierProvider<ImageResultScreenViewModel, List<PhotoIngredient>>(
      ImageResultScreenViewModel.new,
    );

class ImageResultScreenViewModel extends AsyncNotifier<List<PhotoIngredient>> {
  ImageScanRepository get _imageScanRepository =>
      ref.read(imageScanRepositoryProvider);

  UserPantryRepository get _userPantryRepository =>
      ref.read(userPantryRepositoryProvider);

  NotificationService get _notificationService =>
      ref.read(notificationServiceProvider);

  @override
  Future<List<PhotoIngredient>> build() async => const [];

  Future<List<PhotoIngredient>> sendImagetoLLM({
    required String imageType,
    required XFile imageFile,
  }) async {

    try {

      final bytes = await imageFile.readAsBytes();
      final imageBase64 = base64Encode(bytes);

      final mimeType =
          imageFile.mimeType ??
          (imageFile.path.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg');
              
      state = const AsyncValue.loading();

      final results = await _imageScanRepository.scanImage(
        imageBase64: imageBase64,
        imageType: imageType,
        mimeType: mimeType,
      );

      state = AsyncValue.data(results);
      return results;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addIngredientsFromLLMResult({
    required List<PhotoIngredient> ingredients,
    required List<String> amountTexts,
    required List<String> units,
    required List<String> priceTexts,
    required List<DateTime> expiresAts,
  }) async {
    if (ingredients.isEmpty) return;

    if (ingredients.length != amountTexts.length ||
        ingredients.length != units.length ||
        ingredients.length != priceTexts.length ||
        ingredients.length != expiresAts.length) {
      throw ArgumentError(
        'Mismatched lengths: ingredients=${ingredients.length}, '
        'amountTexts=${amountTexts.length}, units=${units.length}',
      );
    }

    try {
      final items = <Map<String, Object?>>[];

      for (var i = 0; i < ingredients.length; i++) {
        final raw = amountTexts[i].trim();
        final normalized = raw.replaceAll(',', '.');
        final amount = double.tryParse(normalized) ?? 0;

        final rawPrice = priceTexts[i].trim();
        final normalizedPrice = rawPrice.replaceAll(',', '.');
        final price = double.tryParse(normalizedPrice) ?? 0;

        items.add({
          'ingredient_id': ingredients[i].ingredient.id,
          'amount': amount,
          'unit': units[i],
          'price_paid': price,
          'expires_at': expiresAts[i].toIso8601String(),
          'is_discounted': ingredients[i].isDiscounted,
        });

        final ingredientName = ingredients[i].ingredient.name;

        _notificationService.scheduleNotification(id: ingredients[i].ingredient.id.createNotificationIdFromUuid(),
          title: NotificationStrings.expiringTitle(price), 
          body: NotificationStrings.expiringBody(ingredientName), 
          scheduledTime: DateTime.now().add(const Duration(seconds: 30)));

      }

      await _userPantryRepository.addIngredientsToPantry(items);



      // Ensure the pantry list is refreshed when the user navigates back.
      ref.invalidate(fridgeViewModelProvider);
    } catch (e) {
      rethrow;
    }
  }


}
