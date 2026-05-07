import 'package:kuchtik/features/pantry/domain/ingredient.dart';

class UserIngredient {
  final String id; // UUID
  final Ingredient ingredient;
  final double amount;
  final String unit;
  final double? pricePaid;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final double? valuePerPiece;
  final bool isLeftover;

  const UserIngredient({
    required this.id,
    required this.ingredient,
    required this.amount,
    required this.unit,
    required this.pricePaid,
    required this.expiresAt,
    required this.createdAt,
    required this.valuePerPiece,
    this.isLeftover = false,
  });

  factory UserIngredient.fromJson(Map<String, dynamic> json) {
    final ingredientJson = json['ingredients'];

    if (ingredientJson == null) {
      throw StateError('Missing nested ingredients object in user_pantry query.');
    }

    return UserIngredient(
      id: json['id'] as String,
      ingredient: Ingredient.fromJson(
        ingredientJson as Map<String, dynamic>,
      ),
      amount: (json['amount'] as num).toDouble(),
      unit: (json['unit'] as String?) ?? 'ks',
      pricePaid: (json['price_paid'] as num?)?.toDouble(),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      valuePerPiece: (json['value_per_piece'] as num?)?.toDouble(),
      isLeftover: json['is_leftover'] as bool? ?? false,
    );
  }

  UserIngredient copyWith({
    String? id,
    Ingredient? ingredient,
    double? amount,
    String? unit,
    Object? pricePaid = _unset,
    Object? expiresAt = _unset,
    Object? createdAt = _unset,
    Object? valuePerPiece = _unset,
    Object? isLeftover = _unset,
  }) {
    return UserIngredient(
      id: id ?? this.id,
      ingredient: ingredient ?? this.ingredient,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      pricePaid: identical(pricePaid, _unset)
          ? this.pricePaid
          : pricePaid as double?,
      expiresAt: identical(expiresAt, _unset)
          ? this.expiresAt
          : expiresAt as DateTime?,
      createdAt: identical(createdAt, _unset)
          ? this.createdAt
          : createdAt as DateTime,
      valuePerPiece: identical(valuePerPiece, _unset)
          ? this.valuePerPiece
          : valuePerPiece as double?,
      isLeftover: identical(isLeftover, _unset)
          ? this.isLeftover          : isLeftover as bool,
    );
  }

  static const Object _unset = Object();
}