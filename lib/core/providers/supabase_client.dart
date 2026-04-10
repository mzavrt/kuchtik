import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Backward-compatible access used in parts of the app.
/// Prefer reading via [supabaseProvider] inside Riverpod-managed code.
final supabase = Supabase.instance.client;

final supabaseProvider = Provider((ref) {
  return supabase;
});

