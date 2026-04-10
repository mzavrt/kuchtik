class RecipeSummary {
  String id;
  String title;
  String imageUrl;
  String? createdBy;
  bool isPublic;
  List<String> tags;

  RecipeSummary({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.createdBy,
    required this.isPublic,
    required this.tags,
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> json, {String? resolvedImageUrl} ) {
    return RecipeSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: resolvedImageUrl ?? (json['image_url'] ?? '') as String, // Use resolved URL if provided, otherwise fallback to raw path or empty string
      createdBy: json['created_by'] as String? ?? '',
      isPublic: json['is_public'] as bool,
      tags: List<String>.from(json['tags'] as List<dynamic>),
    );
  }
}
