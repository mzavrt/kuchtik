class CookRecipePantryUpdateResult {
  const CookRecipePantryUpdateResult({
    required this.removedUserPantryIds,
    required this.expirationChanged,
  });

  final List<String> removedUserPantryIds;
  final List<CookRecipeExpirationChange> expirationChanged;

  factory CookRecipePantryUpdateResult.fromJson(Map<String, dynamic> json) {
    final removedRaw = json['removed'];
    final changedRaw = json['expiration_changed'];

    return CookRecipePantryUpdateResult(
      removedUserPantryIds: removedRaw is List
          ? removedRaw.map((x) => x.toString()).toList(growable: false)
          : const [],
      expirationChanged: changedRaw is List
          ? changedRaw
              .whereType<Map>()
              .map(
                (x) => CookRecipeExpirationChange.fromJson(
                  Map<String, dynamic>.from(x),
                ),
              )
              .toList(growable: false)
          : const [],
    );
  }

  static const empty = CookRecipePantryUpdateResult(
    removedUserPantryIds: [],
    expirationChanged: [],
  );
}

class CookRecipeExpirationChange {
  const CookRecipeExpirationChange({
    required this.userPantryId,
    required this.expiresAt,
  });

  final String userPantryId;
  final DateTime? expiresAt;

  factory CookRecipeExpirationChange.fromJson(Map<String, dynamic> json) {
    final rawExpiresAt = json['expires_at'];

    return CookRecipeExpirationChange(
      userPantryId: json['user_pantry_id'] as String,
      expiresAt: rawExpiresAt == null
          ? null
          : DateTime.parse(rawExpiresAt as String),
    );
  }
}