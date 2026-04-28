class GeneratedRecipeIngredient {
  const GeneratedRecipeIngredient({
    required this.name,
    required this.amount,
    required this.fromInventory,
    this.emoji,
  });

  final String name;
  final String amount;
  final bool fromInventory;
  final String? emoji;

  factory GeneratedRecipeIngredient.fromJson(Map<String, dynamic> json) {
    return GeneratedRecipeIngredient(
      name: (json['name'] as String? ?? '').trim(),
      amount: (json['amount'] as String? ?? '').trim(),
      fromInventory: json['fromInventory'] as bool? ?? false,
      emoji: (json['emoji'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'fromInventory': fromInventory,
      'emoji': emoji,
    };
  }
}