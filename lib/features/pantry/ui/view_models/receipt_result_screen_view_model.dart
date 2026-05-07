import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kuchtik/core/extensions/string_extension.dart';
import 'package:kuchtik/features/pantry/data/repositories/image_scan_repository.dart';
import 'package:kuchtik/features/pantry/domain/photo_ingredient.dart';
import 'package:kuchtik/features/pantry/data/repositories/user_pantry_repository.dart';
import 'package:kuchtik/features/pantry/ui/view_models/pantry_view_model.dart';
import 'package:kuchtik/core/services/notification_service.dart';
import 'package:kuchtik/core/utils/notification_strings.dart';
import 'package:kuchtik/features/pantry/constants/pantry_constants.dart';
import 'package:kuchtik/features/dashboard/ui/view_models/dashboard_view_model.dart';

final receiptResultScreenViewModelProvider =
    AsyncNotifierProvider<ReceiptesultScreenViewModel, List<PhotoIngredient>>(
  ReceiptesultScreenViewModel.new,
);

class ReceiptesultScreenViewModel extends AsyncNotifier<List<PhotoIngredient>> {
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

  double _parseDoubleOrZero(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  DateTime? _defaultExpirationFor(PhotoIngredient item) {
    final days = item.ingredient.defaultUseWithinDays;

    if (days == null || days <= 0) {
      return null;
    }

    return DateTime.now().add(Duration(days: days));
  }

  Map<String, Object?> _payloadRow({
    required PhotoIngredient item,
    required double amount,
    required String unit,
    required double? pricePaid,
    required DateTime? expiresAt,
  }) {
    return {
      'ingredient_id': item.ingredient.id,
      'amount': amount,
      'unit': unit,
      'price_paid': pricePaid,
      'expires_at': expiresAt?.toIso8601String(),
      'value_per_piece':
          unit == 'ks' ? item.ingredient.defaultValuePerPiece : null,
    };
  }

  Future<void> addIngredientsFromLLMResult({
    required List<PhotoIngredient> ingredients,
    required List<String> amountTexts,
    required List<String> priceTexts,
  }) async {
    if (ingredients.isEmpty) return;

    if (ingredients.length != amountTexts.length ||
        ingredients.length != priceTexts.length) {
      throw ArgumentError(
        'Mismatched lengths: ingredients=${ingredients.length}, '
        'amountTexts=${amountTexts.length}, priceTexts=${priceTexts.length}',
      );
    }

    try {
      final items = <Map<String, Object?>>[];

      for (var i = 0; i < ingredients.length; i++) {
        final photoItem = ingredients[i];
        final ingredient = photoItem.ingredient;

        final amount = _parseDoubleOrZero(amountTexts[i]);
        final price = _parseDoubleOrZero(priceTexts[i]);
        final unit = ingredient.derivedUnit;
        final expiresAt = _defaultExpirationFor(photoItem);

        if (amount <= 0) {
          throw StateError('Neplatné množství pro ${ingredient.name}.');
        }

        if (ingredient.isPerPackage) {
          if (unit != 'ks') {
            throw StateError(
              'Ingredience ${ingredient.name} je nastavena jako per_package, '
              'ale výsledná jednotka není ks.',
            );
          }

          final packageCount = amount.round();

          if (packageCount <= 0) {
            throw StateError('Neplatný počet kusů pro ${ingredient.name}.');
          }

          if (amount != packageCount.toDouble()) {
            throw StateError(
              'Počet kusů musí být celé číslo pro ${ingredient.name}.',
            );
          }

          final pricePerPackage = (packageCount > 0 ? price / packageCount : 0).toDouble();

          for (var j = 0; j < packageCount; j++) {
            items.add(
              _payloadRow(
                item: photoItem,
                amount: 1,
                unit: 'ks',
                pricePaid: pricePerPackage > 0 ? pricePerPackage : null,
                expiresAt: expiresAt,
              ),
            );
          }
        } else {
          items.add(
            _payloadRow(
              item: photoItem,
              amount: amount,
              unit: unit,
              pricePaid: price > 0 ? price : null,
              expiresAt: expiresAt,
            ),
          );
        }

      }

      final notificationData = await _userPantryRepository.addIngredientsToPantry(items);

       for (final data in notificationData) {
          // If expiration date is null or too far in the future, we skip scheduling notification.
          if (data.expirationAt == null || data.expirationAt!.isAfter(DateTime.now().add(Duration(days: PantryConstants.notificationExpirationDaysFrom)))) continue;


          _notificationService.scheduleNotification(
            id: data.id.createNotificationIdFromUuid(),
            title: NotificationStrings.expiringTitle(data.price),
            body: NotificationStrings.expiringBody(data.name),
            scheduledTime: data.expirationAt!,
          );
        }


      ref.invalidate(pantryViewModelProvider);
      ref.invalidate(dashboardViewModelProvider);
    } catch (e) {
      rethrow;
    }
  }
}