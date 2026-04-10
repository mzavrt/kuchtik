import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kuchtik/core/providers/supabase_client.dart';
import 'package:kuchtik/features/pantry/domain/photo_ingredient.dart';


final imageScanRepositoryProvider = Provider<ImageScanRepository>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  return ImageScanRepository(supabaseClient);
});


class ImageScanRepository {
  ImageScanRepository(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  Future<List<PhotoIngredient>> scanImage({
    required String imageBase64,
    required String imageType,
    required String mimeType,
  }) async {
    final response = await _supabaseClient.functions.invoke(
      'send-image',
      body: {
        'imageBase64': imageBase64,
        'imageType': imageType,
        'mimeType': mimeType,
      },
    );

    final data = _coerceJsonMap(response.data);
    final rawIngredients = data['ingredients'];

    if (rawIngredients is! List) {
      return const <PhotoIngredient>[];
    }

    return rawIngredients
        .whereType<Map>()
        .map((e) => PhotoIngredient.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Map<String, dynamic> _coerceJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    throw StateError('Unexpected edge function response: ${data.runtimeType}');
  }
}