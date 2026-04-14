class RecipeDashboardItem {
  RecipeDashboardItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.tags,
    this.prepTimeMinutes,
    this.missingOneText,
  });

  final String id;
  final String title;
  final String imageUrl;
  final List<String> tags;

  final int? prepTimeMinutes;
  final String? missingOneText;

  RecipeDashboardItem copyWith({
    String? missingOneText,
    int? prepTimeMinutes,
    List<String>? tags,
    String? imageUrl,
    String? title,
    String? id,
  }) {
    return RecipeDashboardItem(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      missingOneText: missingOneText ?? this.missingOneText,
    );
  }

  factory RecipeDashboardItem.fromJson(
    Map<String, dynamic> json, {
    String? resolvedImageUrl,
    String? missingOneText,
  }) {
    return RecipeDashboardItem(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: resolvedImageUrl ?? (json['image_url'] ?? '') as String,
      tags: List<String>.from((json['tags'] as List<dynamic>? ?? const [])),
      missingOneText: missingOneText,
      prepTimeMinutes: json['prep_time_minutes'] as int?,
    );
  }
}
