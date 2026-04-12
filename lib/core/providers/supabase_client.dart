import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final supabase = Supabase.instance.client;

final supabaseProvider = Provider((ref) {
  return supabase;
});

