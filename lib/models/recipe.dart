import 'dart:ffi';

class Recipe {
  String title;
  String instructions;
  String imageUrl;
  String createdBy;
  bool isPublic;
  List<String> tags;

  Recipe({
    required this.title,
    required this.instructions,
    required this.imageUrl,
    required this.createdBy,
    required this.isPublic,
    required this.tags,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['title'] as String,
      instructions: json['instructions'] as String,
      imageUrl: json['image_url'] as String,
      createdBy: json['created_by'] as String,
      isPublic: json['is_public'] as bool,
      tags: List<String>.from(json['tags'] as List<dynamic>),
    );
  }

  
}