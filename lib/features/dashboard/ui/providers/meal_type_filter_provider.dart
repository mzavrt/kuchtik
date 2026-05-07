// meal_type_filter_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedMealTypeProvider =
    NotifierProvider.autoDispose<SelectedMealTypeNotifier, String?>(
  SelectedMealTypeNotifier.new,
);

class SelectedMealTypeNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? mealType) {
    state = mealType;
  }

  void clear() {
    state = null;
  }
}