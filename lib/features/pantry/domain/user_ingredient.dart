import 'package:kuchtik/features/pantry/domain/ingredient.dart';

class UserIngredient {
  final String id; //UUID
  final Ingredient ingredient;
  final double amount;
  final String unit;
  final double? pricePaid;
  final DateTime? expiresAt;
  final bool isDiscounted;
  final double? actualValuePerPiece;

  UserIngredient({
    required this.id,
    required this.ingredient,
    required this.amount,
    required this.unit,
    required this.pricePaid,
    required this.expiresAt,
    required this.isDiscounted,
    required this.actualValuePerPiece,
  });

  factory UserIngredient.fromJson(Map<String, dynamic> json) {
    return UserIngredient(
      id: json['id'],
      ingredient: Ingredient.fromJson(json['ingredients']), //Table ingredients
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'],
      pricePaid: (json['price_paid'] as num?)?.toDouble(),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      isDiscounted: (json['is_discounted'] as bool?) ?? false,
      actualValuePerPiece:
          (json['actual_value_per_piece'] as num?)?.toDouble(),
    );
  }

  UserIngredient copyWith({
    String? id,
    Ingredient? ingredient,
    double? amount,
    String? unit,
    Object? pricePaid = _unset,
    Object? expiresAt = _unset,
    bool? isDiscounted,
    Object? actualValuePerPiece = _unset,
  }) {
    return UserIngredient(
      id: id ?? this.id,
      ingredient: ingredient ?? this.ingredient,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      pricePaid:
          identical(pricePaid, _unset) ? this.pricePaid : pricePaid as double?,
      expiresAt:
          identical(expiresAt, _unset) ? this.expiresAt : expiresAt as DateTime?,
      isDiscounted: isDiscounted ?? this.isDiscounted,
      actualValuePerPiece: identical(actualValuePerPiece, _unset)
          ? this.actualValuePerPiece
          : actualValuePerPiece as double?,
    );
  }

  static const Object _unset = Object();
}
